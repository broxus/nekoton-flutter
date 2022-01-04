import 'dart:async';
import 'dart:ffi';

import 'package:synchronized/synchronized.dart';

import '../../ffi_utils.dart';
import '../../models/nekoton_exception.dart';
import '../../nekoton.dart';

class NativeGqlTransport {
  final _lock = Lock();
  Pointer<Void>? _ptr;

  NativeGqlTransport(this._ptr);

  bool get isNull => _ptr == null;

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) => _lock.synchronized(() async {
        if (_ptr == null) {
          throw GqlTransportNotFoundException();
        } else {
          return function(_ptr!);
        }
      });

  Future<void> free() => _lock.synchronized(() async {
        if (_ptr == null) {
          throw GqlTransportNotFoundException();
        } else {
          final ptr = _ptr;
          _ptr = null;

          await proceedAsync(
            (port) => nativeLibraryInstance.bindings.free_gql_transport(
              port,
              ptr!,
            ),
          );
        }
      });
}
