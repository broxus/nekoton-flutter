import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../external/gql_connection.dart';
import '../ffi_utils.dart';
import 'models/transport_type.dart';
import 'transport.dart';

class GqlTransport extends Transport {
  final _lock = Lock();
  Pointer<Void>? _ptr;
  late final GqlConnection _gqlConnection;

  GqlTransport._();

  static Future<GqlTransport> create(GqlConnection gqlConnection) async {
    final instance = GqlTransport._();
    await instance._initialize(gqlConnection);
    return instance;
  }

  @override
  TransportType get type => _gqlConnection.type;

  @override
  String get group => _gqlConnection.group;

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
        if (_ptr == null) throw Exception('GqlTransport use after free');

        final ptr = NekotonFlutter.instance().bindings.nt_gql_transport_clone_ptr(
              _ptr!,
            );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() async {
        if (_ptr == null) return;

        NekotonFlutter.instance().bindings.nt_gql_transport_free_ptr(
              _ptr!,
            );

        _ptr = null;
      });

  Future<void> _initialize(GqlConnection gqlConnection) async {
    _gqlConnection = gqlConnection;

    final gqlConnectionPtr = await _gqlConnection.clonePtr();

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_gql_transport_create(
            gqlConnectionPtr,
          ),
    );

    _ptr = Pointer.fromAddress(result as int).cast<Void>();
  }
}
