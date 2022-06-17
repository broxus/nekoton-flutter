import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import '../models/pointer_wrapper.dart';
import '../transport/models/transport_type.dart';
import 'models/gql_connection_post_request.dart';
import 'models/gql_network_settings.dart';

final _nativeFinalizer = NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_gql_connection_free_ptr);

void _attach(PointerWrapper pointerWrapper) => _nativeFinalizer.attach(pointerWrapper, pointerWrapper.ptr);

class GqlConnection {
  late final PointerWrapper pointerWrapper;
  final _postPort = ReceivePort();
  late final StreamSubscription _postSubscription;
  final Future<String> Function({
    required String endpoint,
    required Map<String, String> headers,
    required String data,
  }) post;
  final Future<String> Function(String endpoint) get;
  final String group;
  final type = TransportType.gql;
  final GqlNetworkSettings settings;
  late final _endpointCache = AsyncCache<String>(Duration(milliseconds: settings.latencyDetectionInterval));

  GqlConnection({
    required this.group,
    required this.settings,
    required this.post,
    required this.get,
  }) {
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

    pointerWrapper = PointerWrapper(Pointer.fromAddress(result as int).cast<Void>());

    _attach(pointerWrapper);
  }

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

      if (settings.endpoints.length == 1) {
        endpoint = settings.endpoints.first;
      } else {
        endpoint = await _endpointCache.fetch(_selectQueryingEndpoint);
      }

      ok = await post(
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
    final maxLatency = settings.maxLatency;
    final retryCount = settings.endpointSelectionRetryCount;
    final endpointsCount = settings.endpoints.length;

    for (var i = 0; i < retryCount; i++) {
      try {
        final completer = Completer<String>();

        var checkedEndpoints = 0;

        for (final e in settings.endpoints) {
          _checkLatency(e).whenComplete(() {
            checkedEndpoints++;
          }).then((v) {
            if (!completer.isCompleted) completer.complete(e);
          }).onError((err, st) {
            if (checkedEndpoints == endpointsCount && !completer.isCompleted) completer.completeError(err!, st);
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
    final response = await get('$endpoint?query=%7Binfo%7Bversion%20time%20latency%7D%7D');

    final json = jsonDecode(response) as Map<String, dynamic>;

    final data = json['data'] as Map<String, dynamic>;
    final info = data['info'] as Map<String, dynamic>;
    final latency = info['latency'] as int;

    return latency;
  }
}
