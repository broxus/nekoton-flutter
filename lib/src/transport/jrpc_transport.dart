import 'dart:ffi';

import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/external/jrpc_connection.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/models/transport_type.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_jrpc_transport_free_ptr);

class JrpcTransport extends Transport implements Finalizable {
  late final Pointer<Void> _ptr;
  final JrpcConnection _jrpcConnection;

  JrpcTransport(this._jrpcConnection) {
    final jrpcConnectionPtr = _jrpcConnection.ptr;

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_jrpc_transport_create(
            jrpcConnectionPtr,
          ),
    );

    _ptr = toPtrFromAddress(result as String);

    _nativeFinalizer.attach(this, _ptr);
  }

  @override
  Pointer<Void> get ptr => _ptr;

  @override
  String get name => _jrpcConnection.name;

  @override
  int get networkId => _jrpcConnection.networkId;

  @override
  String get group => _jrpcConnection.group;

  @override
  TransportType get type => _jrpcConnection.type;

  @override
  Future<void> dispose() => _jrpcConnection.dispose();
}
