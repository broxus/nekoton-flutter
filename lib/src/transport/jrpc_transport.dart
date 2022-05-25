import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import 'models/connection_data.dart';
import 'transport.dart';

class JrpcTransport extends Transport {
  final _lock = Lock();
  Pointer<Void>? _ptr;
  @override
  late final ConnectionData connectionData;

  JrpcTransport._();

  static Future<JrpcTransport> create(ConnectionData connectionData) async {
    final instance = JrpcTransport._();
    await instance._initialize(connectionData);
    return instance;
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Jrpc transport use after free');

        final ptr = NekotonFlutter.bindings.nt_jrpc_transport_clone_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) return;

        NekotonFlutter.bindings.nt_jrpc_transport_free_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _initialize(ConnectionData connectionData) => _lock.synchronized(() async {
        this.connectionData = connectionData;

        final endpoint = this.connectionData.endpoints.first;

        final result = executeSync(
          () => NekotonFlutter.bindings.nt_jrpc_transport_create(
            endpoint.toNativeUtf8().cast<Char>(),
          ),
        );

        _ptr = Pointer.fromAddress(result).cast<Void>();
      });
}
