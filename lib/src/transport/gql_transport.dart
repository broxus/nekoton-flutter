import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../constants.dart';
import '../core/models/transaction_id.dart';
import '../ffi_utils.dart';
import '../utils/models/common/full_contract_state.dart';
import '../utils/models/common/transactions_list.dart';
import 'models/connection_data.dart';
import 'models/gql_network_settings.dart';
import 'transport.dart';

class GqlTransport extends Transport {
  final _lock = Lock();
  Pointer<Void>? _ptr;

  GqlTransport._();

  static Future<GqlTransport> create(ConnectionData connectionData) async {
    final storage = GqlTransport._();
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

  Future<String> getLatestBlockId(String address) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_latest_block_id(
        port,
        ptr,
        address.toNativeUtf8().cast<Int8>(),
      ),
    );

    final id = cStringToDart(result);

    return id;
  }

  Future<String> waitForNextBlockId({
    required String currentBlockId,
    required String address,
    required int timeout,
  }) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().wait_for_next_block_id(
        port,
        ptr,
        currentBlockId.toNativeUtf8().cast<Int8>(),
        address.toNativeUtf8().cast<Int8>(),
        timeout,
      ),
    );

    final id = cStringToDart(result);

    return id;
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Gql transport use after free');

        final ptr = bindings().clone_gql_transport_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) return;

        bindings().free_gql_transport_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _initialize(ConnectionData connectionData) async {
    this.connectionData = connectionData;

    final settings = GqlNetworkSettings(
      endpoints: connectionData.endpoints,
      latencyDetectionInterval: kGqlTimeout.inMilliseconds,
      maxLatency: kGqlTimeout.inMilliseconds,
      endpointSelectionRetryCount: 5,
      local: connectionData.local,
    );

    final settingsStr = jsonEncode(settings);

    final result = executeSync(
      () => bindings().create_gql_transport(
        settingsStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    _ptr = Pointer.fromAddress(result).cast<Void>();
  }
}
