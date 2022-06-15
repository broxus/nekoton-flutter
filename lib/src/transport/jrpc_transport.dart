import 'dart:async';
import 'dart:ffi';

import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../external/jrpc_connection.dart';
import '../ffi_utils.dart';
import 'models/transport_type.dart';
import 'transport.dart';

class JrpcTransport extends Transport {
  final _lock = Lock();
  Pointer<Void>? _ptr;
  late final JrpcConnection _jrpcConnection;

  JrpcTransport._();

  static Future<JrpcTransport> create(JrpcConnection jrpcConnection) async {
    final instance = JrpcTransport._();
    await instance._initialize(jrpcConnection);
    return instance;
  }

  @override
  TransportType get type => _jrpcConnection.type;

  @override
  String get group => _jrpcConnection.group;

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('JrpcTransport use after free');

        final ptr = NekotonFlutter.instance().bindings.nt_jrpc_transport_clone_ptr(
              _ptr!,
            );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) return;

        NekotonFlutter.instance().bindings.nt_jrpc_transport_free_ptr(
              _ptr!,
            );

        _ptr = null;
      });

  Future<void> _initialize(JrpcConnection jrpcConnection) async {
    _jrpcConnection = jrpcConnection;

    final jrpcConnectionPtr = await _jrpcConnection.clonePtr();

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_jrpc_transport_create(
            jrpcConnectionPtr,
          ),
    );

    _ptr = Pointer.fromAddress(result as int).cast<Void>();
  }
}
