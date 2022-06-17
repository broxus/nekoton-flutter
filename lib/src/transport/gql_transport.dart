import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../external/gql_connection.dart';
import '../ffi_utils.dart';
import '../models/pointer_wrapper.dart';
import 'models/transport_type.dart';
import 'transport.dart';

final _nativeFinalizer = NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_gql_transport_free_ptr);

void _attach(PointerWrapper pointerWrapper) => _nativeFinalizer.attach(pointerWrapper, pointerWrapper.ptr);

class GqlTransport extends Transport {
  @override
  late final PointerWrapper pointerWrapper;
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
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_gql_transport_get_latest_block_id(
            port,
            pointerWrapper.ptr,
            address.toNativeUtf8().cast<Char>(),
          ),
    );

    final id = result as String;

    return id;
  }

  Future<String> getBlock(String id) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_gql_transport_get_block(
            port,
            pointerWrapper.ptr,
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
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_gql_transport_wait_for_next_block_id(
            port,
            pointerWrapper.ptr,
            currentBlockId.toNativeUtf8().cast<Char>(),
            address.toNativeUtf8().cast<Char>(),
            timeout,
          ),
    );

    final id = result as String;

    return id;
  }

  Future<void> _initialize(GqlConnection gqlConnection) async {
    _gqlConnection = gqlConnection;

    final gqlConnectionPtr = _gqlConnection.pointerWrapper.ptr;

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_gql_transport_create(
            gqlConnectionPtr,
          ),
    );

    pointerWrapper = PointerWrapper(Pointer.fromAddress(result as int).cast<Void>());

    _attach(pointerWrapper);
  }
}
