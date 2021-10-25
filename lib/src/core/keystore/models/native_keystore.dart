import 'dart:async';
import 'dart:ffi';

import '../../../ffi_utils.dart';
import '../../../nekoton.dart';

class NativeKeystore {
  Pointer<Void>? _ptr;

  NativeKeystore(this._ptr);

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) async {
    if (_ptr == null) {
      throw Exception("Keystore not found");
    } else {
      return function(_ptr!);
    }
  }

  Future<void> free() async {
    if (_ptr == null) {
      throw Exception("Keystore not found");
    } else {
      await proceedAsync(
        (port) => nativeLibraryInstance.bindings.free_keystore(
          port,
          _ptr!,
        ),
      );

      _ptr = null;
    }
  }
}
