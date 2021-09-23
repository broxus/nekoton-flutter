import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:ffi/ffi.dart';

import '../ffi_utils.dart';
import '../native_library.dart';
import '../nekoton.dart';
import 'models/connection_data.dart';
import 'models/gql_request.dart';
import 'models/native_gql_connection.dart';

class GqlConnection {
  static GqlConnection? _instance;
  final _nativeLibrary = NativeLibrary.instance();
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

  void free() {
    _nativeLibrary.bindings.free_gql_connection(
      nativeGqlConnection.ptr!,
    );
    nativeGqlConnection.ptr = null;
  }

  Future<void> _initialize(ConnectionData connectionData) async {
    final baseOptions = BaseOptions(
      connectTimeout: connectionData.timeout,
      baseUrl: connectionData.endpoint,
      responseType: ResponseType.plain,
      headers: {"Content-Type": "application/json"},
    );
    _dio = Dio(baseOptions);

    _receivePort.listen(_gqlConnectionListener);

    final connectionResult =
        proceedSync(() => _nativeLibrary.bindings.get_gql_connection(_receivePort.sendPort.nativePort));
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
      nekotonLogger?.e(err, err, st);
    }
  }

  @override
  String toString() => 'GqlConnection(${nativeGqlConnection.ptr?.address})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      other is GqlConnection && other.nativeGqlConnection.ptr?.address == nativeGqlConnection.ptr?.address;

  @override
  int get hashCode => nativeGqlConnection.ptr?.address ?? 0;
}
