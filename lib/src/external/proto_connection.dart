import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/external/models/proto_network_settings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/models/transport_type.dart';
import 'package:tuple/tuple.dart';

typedef ProtoConnectionPost = Future<List<int>> Function({
  required String endpoint,
  required Map<String, String> headers,
  required List<int> data,
});

final _nativeFinalizer = NativeFinalizer(
    NekotonFlutter.instance().bindings.addresses.nt_proto_connection_free_ptr);

class ProtoConnection implements Finalizable {
  late final Pointer<Void> _ptr;
  final _postPort = ReceivePort();
  late final StreamSubscription<Tuple2<String, String>> _postSubscription;
  final ProtoConnectionPost _post;
  final String _name;
  final int _networkId;
  final String _group;
  final _type = TransportType.proto;
  final ProtoNetworkSettings _settings;

  ProtoConnection({
    required ProtoConnectionPost post,
    required String name,
    required int networkId,
    required String group,
    required ProtoNetworkSettings settings,
  })  : _post = post,
        _name = name,
        _networkId = networkId,
        _group = group,
        _settings = settings {
    _postSubscription = _postPort.cast<String>().map((e) {
      final json = jsonDecode(e) as List<dynamic>;

      final tx = json.first as String;
      final data = json.last as String;

      return Tuple2(tx, data);
    }).listen(_postRequestHandler);

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_proto_connection_create(
            _postPort.sendPort.nativePort,
          ),
    );

    _ptr = toPtrFromAddress(result as String);

    _nativeFinalizer.attach(this, _ptr);
  }

  Pointer<Void> get ptr => _ptr;

  String get name => _name;

  int get networkId => _networkId;

  String get group => _group;

  TransportType get type => _type;

  Future<void> dispose() async {
    await _postSubscription.cancel();

    _postPort.close();
  }

  Future<void> _postRequestHandler(Tuple2<String, String> event) async {
    final tx = toPtrFromAddress(event.item1);

    List<int>? ok;
    String? err;

    try {
      // Decode base64 data received from Rust
      final binaryData = base64Decode(event.item2);

      // Call the post function with binary data
      ok = await _post(
        endpoint: _settings.endpoint,
        headers: {
          'Content-Type': 'application/x-protobuf',
        },
        data: binaryData,
      );
    } catch (error) {
      err = error.toString();
    }

    // Encode response back to base64 for Rust
    final encodedResponse = ok != null ? base64Encode(ok) : null;

    NekotonFlutter.instance().bindings.nt_external_resolve_request_with_string(
          tx,
          encodedResponse?.toNativeUtf8().cast<Char>() ?? nullptr,
          err?.toNativeUtf8().cast<Char>() ?? nullptr,
        );
  }
}
