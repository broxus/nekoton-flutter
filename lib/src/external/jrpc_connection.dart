import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import '../models/pointed.dart';
import '../transport/models/transport_type.dart';
import 'models/jrpc_connection_post_request.dart';
import 'models/jrpc_network_settings.dart';

class JrpcConnection implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;
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

    _ptr = Pointer.fromAddress(result as int).cast<Void>();
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('JrpcConnection use after free');

        final ptr = NekotonFlutter.instance().bindings.nt_storage_clone_ptr(
              _ptr!,
            );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() async {
        await _postSubscription.cancel();

        _postPort.close();

        if (_ptr == null) return;

        NekotonFlutter.instance().bindings.nt_storage_free_ptr(
              _ptr!,
            );

        _ptr = null;
      });

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
