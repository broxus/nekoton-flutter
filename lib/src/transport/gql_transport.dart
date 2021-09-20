import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';

import '../core/models/transaction_id.dart';
import '../external/gql_connection.dart';
import '../ffi_utils.dart';
import '../native_library.dart';
import 'models/native_gql_transport.dart';
import 'transport.dart';

class GqlTransport implements Transport {
  static GqlTransport? _instance;
  final _nativeLibrary = NativeLibrary.instance();
  final Logger? _logger;
  late final GqlConnection _gqlConnection;
  late final NativeGqlTransport nativeGqlTransport;

  GqlTransport._(this._logger);

  static Future<GqlTransport> getInstance({
    Logger? logger,
  }) async {
    if (_instance == null) {
      final instance = GqlTransport._(logger);
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  @override
  Future<Map<String, dynamic>> getContractState({
    required String address,
  }) async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_contract_state(
          port,
          nativeGqlTransport.ptr!,
          address.toNativeUtf8().cast<Int8>(),
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;

    return json;
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactions({
    required String address,
    required TransactionId from,
    required int count,
  }) async {
    final fromStr = jsonEncode(from.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_transactions(
          port,
          nativeGqlTransport.ptr!,
          address.toNativeUtf8().cast<Int8>(),
          fromStr.toNativeUtf8().cast<Int8>(),
          count,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<Map<String, dynamic>>;

    return json;
  }

  Future<String> getLatestBlockId(String address) async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_latest_block_id(
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
    final result = await proceedAsync((port) => _nativeLibrary.bindings.wait_for_next_block_id(
          port,
          nativeGqlTransport.ptr!,
          currentBlockId.toNativeUtf8().cast<Int8>(),
          address.toNativeUtf8().cast<Int8>(),
        ));

    final nextBlockId = cStringToDart(result);

    return nextBlockId;
  }

  Future<void> _initialize() async {
    _gqlConnection = await GqlConnection.getInstance(logger: _logger);

    final transportResult = await proceedAsync(
        (port) => _nativeLibrary.bindings.get_gql_transport(port, _gqlConnection.nativeGqlConnection.ptr!));
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
