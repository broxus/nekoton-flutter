import 'dart:async';
import 'dart:ffi';

import 'package:nekoton_flutter/src/nekoton.dart';

import '../../../ffi_utils.dart';

class NativeTonWallet {
  Pointer<Void>? _ptr;

  NativeTonWallet(this._ptr);

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) async {
    if (_ptr == null) {
      throw Exception("Ton wallet not found");
    } else {
      return function(_ptr!);
    }
  }

  Future<void> free() async {
    if (_ptr == null) {
      throw Exception("Ton wallet not found");
    } else {
      await proceedAsync(
        (port) => nativeLibraryInstance.bindings.free_ton_wallet(
          port,
          _ptr!,
        ),
      );

      _ptr = null;
    }
  }
}
