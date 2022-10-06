import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import 'constants.dart';
import 'models/connection_data.dart';
import 'models/gql_network_settings.dart';
import 'transport.dart';

class GqlTransport extends Transport {
  final _lock = Lock();
  Pointer<Void>? _ptr;
  @override
  late final ConnectionData connectionData;

  GqlTransport._();

  static Future<GqlTransport> create(ConnectionData connectionData) async {
    final instance = GqlTransport._();
    await instance._initialize(connectionData);
    return instance;
  }

  Future<String> getLatestBlockId(String address) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_gql_transport_get_latest_block_id(
            port,
            ptr,
            address.toNativeUtf8().cast<Char>(),
          ),
    );

    final id = result as String;

    return id;
  }

  Future<String> getBlock(String id) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_gql_transport_get_block(
            port,
            ptr,
            id.toNativeUtf8().cast<Char>(),
          ),
    );

    final block = result as String;

    return block;
  }

  Future<String> waitForNextBlockId({
    required String currentBlockId,
    required String address,
    required int timeout,
  }) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_gql_transport_wait_for_next_block_id(
            port,
            ptr,
            currentBlockId.toNativeUtf8().cast<Char>(),
            address.toNativeUtf8().cast<Char>(),
            timeout,
          ),
    );

    final id = result as String;

    return id;
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Gql transport use after free');

        final ptr = NekotonFlutter.instance().bindings.nt_gql_transport_clone_ptr(
              _ptr!,
            );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) return;

        NekotonFlutter.instance().bindings.nt_gql_transport_free_ptr(
              _ptr!,
            );

        _ptr = null;
      });

  Future<void> _initialize(ConnectionData connectionData) => _lock.synchronized(() async {
        this.connectionData = connectionData;

        final settings = GqlNetworkSettings(
          endpoints: connectionData.endpoints,
          latencyDetectionInterval: kGqlTimeout.inMilliseconds,
          maxLatency: kGqlTimeout.inMilliseconds,
          endpointSelectionRetryCount: 5,
          local: connectionData.local,
        );

        final settingsStr = jsonEncode(settings);

        final result = executeSync(
          () => NekotonFlutter.instance().bindings.nt_gql_transport_create(
                settingsStr.toNativeUtf8().cast<Char>(),
              ),
        );

        _ptr = toPtrFromAddress(result as String);
      });
}
