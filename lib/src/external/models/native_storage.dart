import 'dart:async';
import 'dart:ffi';

import 'package:nekoton_flutter/src/nekoton.dart';

class NativeStorage {
  Completer<void>? _completer;
  Pointer<Void>? _ptr;

  NativeStorage(this._ptr);

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) async {
    await _completer?.future;

    if (_ptr == null) {
      throw Exception("Storage not found");
    } else {
      _completer = Completer<void>();
      return function(_ptr!)
        ..then((_) {
          if (_completer != null && !_completer!.isCompleted) {
            _completer?.complete();
          }
        }).onError((_, __) {
          if (_completer != null && !_completer!.isCompleted) {
            _completer?.complete();
          }
        });
    }
  }

  Future<void> free() async {
    await _completer?.future;
    _completer = Completer<void>();

    if (_ptr == null) {
      throw Exception("Storage not found");
    } else {
      nativeLibraryInstance.bindings.free_storage(_ptr!);
      _ptr = null;
    }

    if (_completer != null && !_completer!.isCompleted) {
      _completer?.complete();
    }
  }
}
