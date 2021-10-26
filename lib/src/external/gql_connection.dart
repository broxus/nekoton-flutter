import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:ffi/ffi.dart';

import '../ffi_utils.dart';
import '../nekoton.dart';
import 'models/connection_data.dart';
import 'models/gql_request.dart';
import 'models/native_gql_connection.dart';

class GqlConnection {
  static GqlConnection? _instance;
  late final Dio _dio;
  final _receivePort = ReceivePort();
  late final NativeGqlConnection nativeGqlConnection;

  GqlConnection._();

  static Future<GqlConnection> getInstance(ConnectionData connectionData) async {
    if (_instance == null) {
      final instance = GqlConnection._();
      await instance._initialize(connectionData);
      _instance = instance;
    }

    return _instance!;
  }

  Future<void> free() => nativeGqlConnection.free();

  Future<void> _initialize(ConnectionData connectionData) async {
    final baseOptions = BaseOptions(
      connectTimeout: connectionData.timeout,
      baseUrl: connectionData.endpoint,
      responseType: ResponseType.plain,
      headers: {'Content-Type': 'application/json'},
    );
    _dio = Dio(baseOptions);

    _receivePort.listen(_gqlConnectionListener);

    final connectionResult =
        proceedSync(() => nativeLibraryInstance.bindings.get_gql_connection(_receivePort.sendPort.nativePort));
    final connectionPtr = Pointer.fromAddress(connectionResult).cast<Void>();
    nativeGqlConnection = NativeGqlConnection(connectionPtr);
  }

  Future<void> _gqlConnectionListener(dynamic data) async {
    try {
      if (data is! String) {
        return;
      }

      final json = jsonDecode(data) as Map<String, dynamic>;
      final request = GqlRequest.fromJson(json);
      final tx = request.tx.toString();

      Pointer<Int8> value = Pointer.fromAddress(0).cast<Int8>();
      bool isSuccessful = false;

      try {
        final response = await _dio.post('graphql', data: request.data);
        final responseData = response.data as String;
        value = responseData.toNativeUtf8().cast<Int8>();

        isSuccessful = true;
      } catch (err) {
        value = err.toString().toNativeUtf8().cast<Int8>();
      }

      nativeLibraryInstance.bindings.resolve_gql_request(
        tx.toNativeUtf8().cast<Int8>(),
        isSuccessful ? 1 : 0,
        value,
      );
    } catch (err, st) {
      nekotonLogger?.e(err, err, st);
    }
  }
}
