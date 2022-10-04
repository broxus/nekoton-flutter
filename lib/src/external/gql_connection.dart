import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/external/models/gql_network_settings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/models/nekoton_exception.dart';
import 'package:nekoton_flutter/src/transport/models/transport_type.dart';
import 'package:tuple/tuple.dart';

typedef GqlConnectionPost = Future<String> Function({
  required String endpoint,
  required Map<String, String> headers,
  required String data,
});

typedef GqlConnectionGet = Future<String> Function(String endpoint);

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_gql_connection_free_ptr);

class GqlConnection implements Finalizable {
  late final Pointer<Void> _ptr;
  final _postPort = ReceivePort();
  late final StreamSubscription<Tuple2<String, String>> _postSubscription;
  final GqlConnectionPost _post;
  final GqlConnectionGet _get;
  final String _name;
  final int _networkId;
  final String _group;
  final _type = TransportType.gql;
  final GqlNetworkSettings _settings;
  late final _endpointCache =
      AsyncCache<String>(Duration(milliseconds: _settings.latencyDetectionInterval));

  GqlConnection({
    required GqlConnectionPost post,
    required GqlConnectionGet get,
    required String name,
    required int networkId,
    required String group,
    required GqlNetworkSettings settings,
  })  : _post = post,
        _get = get,
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
      () => NekotonFlutter.instance().bindings.nt_gql_connection_create(
            settings.local ? 1 : 0,
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
        data: event.item2,
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

    throw NekotonException('No available endpoints found');
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
