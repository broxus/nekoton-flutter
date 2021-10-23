import 'dart:async';
import 'dart:ffi';

import 'package:nekoton_flutter/src/nekoton.dart';

import '../../ffi_utils.dart';

class NativeStorage {
  Pointer<Void>? _ptr;

  NativeStorage(this._ptr);

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) async {
    if (_ptr == null) {
      throw Exception("Storage not found");
    } else {
      return function(_ptr!);
    }
  }

  Future<void> free() async {
    if (_ptr == null) {
      throw Exception("Storage not found");
    } else {
      await proceedAsync(
        (port) => nativeLibraryInstance.bindings.free_storage(
          port,
          _ptr!,
        ),
      );

      _ptr = null;
    }
  }
}
