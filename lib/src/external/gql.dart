import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';

import '../ffi_utils.dart';
import '../native_library.dart';
import 'models/gql_request.dart';
import 'models/native_connection.dart';
import 'models/native_transport.dart';

class Gql {
  static Gql? _instance;
  final _nativeLibrary = NativeLibrary.instance();
  final Logger? _logger;
  late final Dio _dio;
  final _receivePort = ReceivePort();
  late final NativeConnection _nativeConnection;
  late final NativeTransport nativeTransport;

  Gql._(this._logger);

  static Future<Gql> getInstance({
    Logger? logger,
  }) async {
    if (_instance == null) {
      final instance = Gql._(logger);
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Future<String> getLatestBlockId(String address) async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_latest_block_id(
          port,
          nativeTransport.ptr!,
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
          nativeTransport.ptr!,
          currentBlockId.toNativeUtf8().cast<Int8>(),
          address.toNativeUtf8().cast<Int8>(),
        ));

    final nextBlockId = cStringToDart(result);

    return nextBlockId;
  }

  Future<void> _initialize() async {
    final baseOptions = BaseOptions(
      connectTimeout: 60000,
      receiveTimeout: 60000,
      sendTimeout: 60000,
      baseUrl: "https://main2.ton.dev/",
      responseType: ResponseType.plain,
      headers: {"Content-Type": "application/json"},
    );
    _dio = Dio(baseOptions);

    _receivePort.listen(_gqlListener);

    final connectionResult =
        proceedSync(() => _nativeLibrary.bindings.get_gql_connection(_receivePort.sendPort.nativePort));
    final connectionPtr = Pointer.fromAddress(connectionResult).cast<Void>();
    _nativeConnection = NativeConnection(connectionPtr);

    final transportResult =
        await proceedAsync((port) => _nativeLibrary.bindings.get_gql_transport(port, _nativeConnection.ptr!));
    final transportPtr = Pointer.fromAddress(transportResult).cast<Void>();
    nativeTransport = NativeTransport(transportPtr);
  }

  Future<void> _gqlListener(dynamic data) async {
    try {
      if (data is! String) {
        return;
      }

      final json = jsonDecode(data) as Map<String, dynamic>;
      final request = GqlRequest.fromJson(json);
      final tx = Pointer.fromAddress(request.tx).cast<Void>();

      Pointer<Int8> value = Pointer.fromAddress(0).cast<Int8>();
      int isSuccessful = 0;

      try {
        final response = await _dio.post("graphql", data: request.data);
        final responseData = response.data as String;
        value = responseData.toNativeUtf8().cast<Int8>();

        isSuccessful = 1;
      } catch (err) {
        value = err.toString().toNativeUtf8().cast<Int8>();
      }

      _nativeLibrary.bindings.resolve_gql_request(tx, isSuccessful, value);
    } catch (err, st) {
      _logger?.e(err, err, st);
    }
  }
}
