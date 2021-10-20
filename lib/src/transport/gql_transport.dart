import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../core/models/transaction_id.dart';
import '../external/gql_connection.dart';
import '../external/models/connection_data.dart';
import '../ffi_utils.dart';
import '../nekoton.dart';
import '../provider/models/full_contract_state.dart';
import '../provider/models/transactions_list.dart';
import 'models/native_gql_transport.dart';
import 'transport.dart';

class GqlTransport implements Transport {
  static GqlTransport? _instance;
  late final GqlConnection _gqlConnection;
  late final NativeGqlTransport nativeGqlTransport;
  @override
  late final ConnectionData connectionData;

  GqlTransport._();

  static Future<GqlTransport> getInstance(ConnectionData connectionData) async {
    if (_instance == null) {
      final instance = GqlTransport._();
      await instance._initialize(connectionData);
      _instance = instance;
    }

    return _instance!;
  }

  @override
  Future<FullContractState?> getFullAccountState({
    required String address,
  }) async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_full_account_state(
          port,
          nativeGqlTransport.ptr!,
          address.toNativeUtf8().cast<Int8>(),
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>?;

    if (json == null) {
      return null;
    }

    final fullContractState = FullContractState.fromJson(json);

    return fullContractState;
  }

  @override
  Future<TransactionsList> getTransactions({
    required String address,
    TransactionId? continuation,
    int? limit,
  }) async {
    final fromPtr = continuation != null ? jsonEncode(continuation).toNativeUtf8().cast<Int8>() : nullptr;

    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_transactions(
          port,
          nativeGqlTransport.ptr!,
          address.toNativeUtf8().cast<Int8>(),
          fromPtr,
          limit ?? 50,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final transactionsList = TransactionsList.fromJson(json);

    return transactionsList;
  }

  Future<String> getLatestBlockId(String address) async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_latest_block_id(
          port,
          nativeGqlTransport.ptr!,
          address.toNativeUtf8().cast<Int8>(),
        ));

    final id = cStringToDart(result);

    return id;
  }

  Future<String> waitForNextBlockId({
    required String currentBlockId,
    required String address,
  }) async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.wait_for_next_block_id(
          port,
          nativeGqlTransport.ptr!,
          currentBlockId.toNativeUtf8().cast<Int8>(),
          address.toNativeUtf8().cast<Int8>(),
        ));

    final nextBlockId = cStringToDart(result);

    return nextBlockId;
  }

  void free() {
    nativeLibraryInstance.bindings.free_gql_transport(
      nativeGqlTransport.ptr!,
    );
    nativeGqlTransport.ptr = null;
  }

  Future<void> _initialize(ConnectionData connectionData) async {
    this.connectionData = connectionData;

    _gqlConnection = await GqlConnection.getInstance(connectionData);

    final transportResult = await proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_gql_transport(port, _gqlConnection.nativeGqlConnection.ptr!));
    final transportPtr = Pointer.fromAddress(transportResult).cast<Void>();
    nativeGqlTransport = NativeGqlTransport(transportPtr);
  }

  @override
  String toString() => 'GqlTransport(${nativeGqlTransport.ptr?.address})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      other is GqlTransport && other.nativeGqlTransport.ptr?.address == nativeGqlTransport.ptr?.address;

  @override
  int get hashCode => nativeGqlTransport.ptr?.address ?? 0;
}
