import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../ffi_utils.dart';
import '../nekoton.dart';
import 'models/connection_data.dart';
import 'models/native_gql_connection.dart';

class GqlConnection {
  static GqlConnection? _instance;
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
    final result = proceedSync(
      () => nativeLibraryInstance.bindings.get_gql_connection(
        connectionData.endpoint.toNativeUtf8().cast<Int8>(),
      ),
    );
    final ptr = Pointer.fromAddress(result).cast<Void>();
    nativeGqlConnection = NativeGqlConnection(ptr);
  }
}
