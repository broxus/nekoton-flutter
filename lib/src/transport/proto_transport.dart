import 'dart:ffi';

import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/external/proto_connection.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/models/transport_type.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';

final _nativeFinalizer = NativeFinalizer(
    NekotonFlutter.instance().bindings.addresses.nt_proto_transport_free_ptr);

class ProtoTransport extends Transport implements Finalizable {
  late final Pointer<Void> _ptr;
  final ProtoConnection _protoConnection;

  ProtoTransport(this._protoConnection) {
    final protoConnectionPtr = _protoConnection.ptr;

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_proto_transport_create(
            protoConnectionPtr,
          ),
    );

    _ptr = toPtrFromAddress(result as String);

    _nativeFinalizer.attach(this, _ptr);
  }

  @override
  Pointer<Void> get ptr => _ptr;

  @override
  String get name => _protoConnection.name;

  @override
  int get networkId => _protoConnection.networkId;

  @override
  String get group => _protoConnection.group;

  @override
  TransportType get type => _protoConnection.type;

  @override
  Future<void> dispose() => _protoConnection.dispose();
}
