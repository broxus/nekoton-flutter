import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/external/models/gql_connection_post_request.dart';
import 'package:nekoton_flutter/src/external/models/gql_network_settings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/models/transport_type.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_gql_connection_free_ptr);

class GqlConnection implements Finalizable {
  late final Pointer<Void> _ptr;
  final _postPort = ReceivePort();
  late final StreamSubscription<GqlConnectionPostRequest> _postSubscription;
  final Future<String> Function({
    required String endpoint,
    required Map<String, String> headers,
    required String data,
  }) _post;
  final Future<String> Function(String endpoint) _get;
  final String _name;
  final String _group;
  final _type = TransportType.gql;
  final GqlNetworkSettings _settings;
  late final _endpointCache =
      AsyncCache<String>(Duration(milliseconds: _settings.latencyDetectionInterval));

  GqlConnection({
    required Future<String> Function({
      required String endpoint,
      required Map<String, String> headers,
      required String data,
    })
        post,
    required Future<String> Function(String endpoint) get,
    required String name,
    required String group,
    required GqlNetworkSettings settings,
  })  : _post = post,
        _get = get,
        _name = name,
        _group = group,
        _settings = settings {
    _postSubscription = _postPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = GqlConnectionPostRequest.fromJson(json);
      return payload;
    }).listen(_postRequestHandler);

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_gql_connection_create(
            settings.local ? 1 : 0,
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

  Future<void> _postRequestHandler(GqlConnectionPostRequest event) async {
    final tx = Pointer.fromAddress(event.tx).cast<Void>();

    String? ok;
    String? err;

    try {
      String endpoint;

      if (_settings.endpoints.length == 1) {
        endpoint = _settings.endpoints.first;
      } else {
        endpoint = await _endpointCache.fetch(_selectQueryingEndpoint);
      }

      ok = await _post(
        endpoint: endpoint,
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

  Future<String> _selectQueryingEndpoint() async {
    final maxLatency = _settings.maxLatency;
    final retryCount = _settings.endpointSelectionRetryCount;
    final endpointsCount = _settings.endpoints.length;

    for (var i = 0; i < retryCount; i++) {
      try {
        final completer = Completer<String>();

        var checkedEndpoints = 0;

        for (final e in _settings.endpoints) {
          _checkLatency(e).whenComplete(() {
            checkedEndpoints++;
          }).then((v) {
            if (!completer.isCompleted) completer.complete(e);
          }).onError((err, st) {
            if (checkedEndpoints == endpointsCount && !completer.isCompleted) {
              completer.completeError(err!, st);
            }
          });
        }

        return await completer.future.timeout(Duration(milliseconds: maxLatency));
      } catch (err, st) {
        debugPrint(err.toString());
        debugPrint(st.toString());
      }
    }

    throw Exception('No available endpoints found');
  }

  Future<int> _checkLatency(String endpoint) async {
    final response = await _get('$endpoint?query=%7Binfo%7Bversion%20time%20latency%7D%7D');

    final json = jsonDecode(response) as Map<String, dynamic>;

    final data = json['data'] as Map<String, dynamic>;
    final info = data['info'] as Map<String, dynamic>;
    final latency = info['latency'] as int;

    return latency;
  }
}
