import 'dart:async';
import 'dart:ffi';

import 'package:synchronized/synchronized.dart';

import '../../../ffi_utils.dart';
import '../../../models/nekoton_exception.dart';
import '../../../nekoton.dart';

class NativeGenericContract {
  final _lock = Lock();
  Pointer<Void>? _ptr;

  NativeGenericContract(this._ptr);

  bool get isNull => _ptr == null;

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) => _lock.synchronized(() async {
        if (_ptr == null) {
          throw GenericContractNotFoundException();
        } else {
          return function(_ptr!);
        }
      });

  Future<void> free() => _lock.synchronized(() async {
        if (_ptr == null) {
          throw GenericContractNotFoundException();
        } else {
          final ptr = _ptr;
          _ptr = null;

          await proceedAsync(
            (port) => nativeLibraryInstance.bindings.free_generic_contract(
              port,
              ptr!,
            ),
          );
        }
      });
}
