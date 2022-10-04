import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/external/gql_connection.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/models/transport_type.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_gql_transport_free_ptr);

class GqlTransport extends Transport implements Finalizable {
  late final Pointer<Void> _ptr;
  final GqlConnection _gqlConnection;

  GqlTransport(this._gqlConnection) {
    final gqlConnectionPtr = _gqlConnection.ptr;

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_gql_transport_create(
            gqlConnectionPtr,
          ),
    );

    _ptr = toPtrFromAddress(result as String);

    _nativeFinalizer.attach(this, _ptr);
  }

  @override
  Pointer<Void> get ptr => _ptr;

  @override
  String get name => _gqlConnection.name;

  @override
  int get networkId => _gqlConnection.networkId;

  @override
  String get group => _gqlConnection.group;

  @override
  TransportType get type => _gqlConnection.type;

  Future<String> getLatestBlockId(String address) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_gql_transport_get_latest_block_id(
            port,
            ptr,
            address.toNativeUtf8().cast<Char>(),
          ),
    );

    final id = result as String;

    return id;
  }

  Future<String> getBlock(String id) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_gql_transport_get_block(
            port,
            ptr,
            id.toNativeUtf8().cast<Char>(),
          ),
    );

    final block = result as String;

    return block;
  }

  Future<String> waitForNextBlockId({
    required String currentBlockId,
    required String address,
    required int timeout,
  }) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_gql_transport_wait_for_next_block_id(
            port,
            ptr,
            currentBlockId.toNativeUtf8().cast<Char>(),
            address.toNativeUtf8().cast<Char>(),
            timeout,
          ),
    );

    final id = result as String;

    return id;
  }

  @override
  Future<void> dispose() => _gqlConnection.dispose();
}
