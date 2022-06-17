import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import '../models/pointer_wrapper.dart';
import '../transport/models/transport_type.dart';
import 'models/jrpc_connection_post_request.dart';
import 'models/jrpc_network_settings.dart';

final _nativeFinalizer = NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_jrpc_connection_free_ptr);

void _attach(PointerWrapper pointerWrapper) => _nativeFinalizer.attach(pointerWrapper, pointerWrapper.ptr);

class JrpcConnection {
  late final PointerWrapper pointerWrapper;
  final _postPort = ReceivePort();
  late final StreamSubscription _postSubscription;
  final Future<String> Function({
    required String endpoint,
    required Map<String, String> headers,
    required String data,
  }) post;
  final String group;
  final type = TransportType.jrpc;
  final JrpcNetworkSettings settings;

  JrpcConnection({
    required this.group,
    required this.settings,
    required this.post,
  }) {
    _postSubscription = _postPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = JrpcConnectionPostRequest.fromJson(json);
      return payload;
    }).listen(_postRequestHandler);

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_jrpc_connection_create(
            _postPort.sendPort.nativePort,
          ),
    );

    pointerWrapper = PointerWrapper(Pointer.fromAddress(result as int).cast<Void>());

    _attach(pointerWrapper);
  }

  Future<void> dispose() async {
    await _postSubscription.cancel();

    _postPort.close();
  }

  Future<void> _postRequestHandler(JrpcConnectionPostRequest event) async {
    final tx = Pointer.fromAddress(event.tx).cast<Void>();

    String? ok;
    String? err;

    try {
      ok = await post(
        endpoint: settings.endpoint,
        headers: {
          'Content-Type': 'application/json',
        },
        data: event.data,
      );
    } catch (error) {
      err = error.toString();
    }

    NekotonFlutter.instance().bindings.nt_external_resolve_request_with_string(
          tx,
          ok?.toNativeUtf8().cast<Char>() ?? nullptr,
          err?.toNativeUtf8().cast<Char>() ?? nullptr,
        );
  }
}
