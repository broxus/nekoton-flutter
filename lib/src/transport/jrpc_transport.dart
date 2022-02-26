import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../core/models/transaction_id.dart';
import '../ffi_utils.dart';
import '../utils/models/common/full_contract_state.dart';
import '../utils/models/common/transactions_list.dart';
import 'models/connection_data.dart';
import 'transport.dart';

class JrpcTransport extends Transport {
  final _lock = Lock();
  Pointer<Void>? _ptr;

  JrpcTransport._();

  static Future<JrpcTransport> create(ConnectionData connectionData) async {
    final storage = JrpcTransport._();
    await storage._initialize(connectionData);
    return storage;
  }

  @override
  Future<FullContractState?> getFullAccountState({
    required String address,
  }) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_full_account_state(
        port,
        ptr,
        connectionData.type.index,
        address.toNativeUtf8().cast<Int8>(),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>?;
    final fullContractState = json != null ? FullContractState.fromJson(json) : null;

    return fullContractState;
  }

  @override
  Future<TransactionsList> getTransactions({
    required String address,
    TransactionId? continuation,
    int? limit,
  }) async {
    final ptr = await clonePtr();

    final fromStr = continuation != null ? jsonEncode(continuation) : null;

    final result = await executeAsync(
      (port) => bindings().get_transactions(
        port,
        ptr,
        connectionData.type.index,
        address.toNativeUtf8().cast<Int8>(),
        fromStr?.toNativeUtf8().cast<Int8>() ?? nullptr,
        limit ?? 50,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final transactionsList = TransactionsList.fromJson(json);

    return transactionsList;
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Jrpc transport use after free');

        final ptr = bindings().clone_jrpc_transport_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Jrpc transport use after free');

        bindings().free_jrpc_transport_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _initialize(ConnectionData connectionData) async {
    this.connectionData = connectionData;

    final endpoint = this.connectionData.endpoints.first;

    final result = executeSync(
      () => bindings().create_jrpc_transport(
        endpoint.toNativeUtf8().cast<Int8>(),
      ),
    );

    _ptr = Pointer.fromAddress(result).cast<Void>();
  }
}
