import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/external/models/jrpc_connection_post_request.dart';
import 'package:nekoton_flutter/src/external/models/jrpc_network_settings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/models/transport_type.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_jrpc_connection_free_ptr);

class JrpcConnection implements Finalizable {
  late final Pointer<Void> _ptr;
  final _postPort = ReceivePort();
  late final StreamSubscription<JrpcConnectionPostRequest> _postSubscription;
  final Future<String> Function({
    required String endpoint,
    required Map<String, String> headers,
    required String data,
  }) _post;
  final String _name;
  final String _group;
  final _type = TransportType.jrpc;
  final JrpcNetworkSettings _settings;

  JrpcConnection({
    required Future<String> Function({
      required String endpoint,
      required Map<String, String> headers,
      required String data,
    })
        post,
    required String name,
    required String group,
    required JrpcNetworkSettings settings,
  })  : _post = post,
        _name = name,
        _group = group,
        _settings = settings {
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

    _ptr = Pointer.fromAddress(result as int).cast<Void>();

    _nativeFinalizer.attach(this, _ptr);
  }

  Pointer<Void> get ptr => _ptr;

  String get name => _name;

  String get group => _group;

  TransportType get type => _type;

  Future<void> dispose() async {
    await _postSubscription.cancel();

    _postPort.close();
  }

  Future<void> _postRequestHandler(JrpcConnectionPostRequest event) async {
    final tx = Pointer.fromAddress(event.tx).cast<Void>();

    String? ok;
    String? err;

    try {
      ok = await _post(
        endpoint: _settings.endpoint,
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
