import 'dart:async';
import 'dart:ffi';

import '../bindings.dart';
import '../external/jrpc_connection.dart';
import '../ffi_utils.dart';
import '../models/pointer_wrapper.dart';
import 'models/transport_type.dart';
import 'transport.dart';

final _nativeFinalizer = NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_jrpc_transport_free_ptr);

void _attach(PointerWrapper pointerWrapper) => _nativeFinalizer.attach(pointerWrapper, pointerWrapper.ptr);

class JrpcTransport extends Transport {
  @override
  late final PointerWrapper pointerWrapper;
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

  Future<void> _initialize(JrpcConnection jrpcConnection) async {
    _jrpcConnection = jrpcConnection;

    final jrpcConnectionPtr = _jrpcConnection.pointerWrapper.ptr;

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_jrpc_transport_create(
            jrpcConnectionPtr,
          ),
    );

    pointerWrapper = PointerWrapper(Pointer.fromAddress(result as int).cast<Void>());

    _attach(pointerWrapper);
  }
}
