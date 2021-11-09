import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../ffi_utils.dart';
import '../nekoton.dart';
import 'models/connection_data.dart';
import 'models/native_gql_connection.dart';

class GqlConnection {
  late final NativeGqlConnection nativeGqlConnection;

  GqlConnection._();

  static Future<GqlConnection> create(ConnectionData connectionData) async {
    final gqlConnection = GqlConnection._();
    await gqlConnection._initialize(connectionData);
    return gqlConnection;
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
