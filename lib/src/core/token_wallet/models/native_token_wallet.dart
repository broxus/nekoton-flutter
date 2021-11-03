import 'dart:async';
import 'dart:ffi';

import '../../../ffi_utils.dart';
import '../../../models/nekoton_exception.dart';
import '../../../nekoton.dart';

class NativeTokenWallet {
  Pointer<Void>? _ptr;

  NativeTokenWallet(this._ptr);

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) async {
    if (_ptr == null) {
      throw TokenWalletNotFoundException();
    } else {
      return function(_ptr!);
    }
  }

  Future<void> free() async {
    if (_ptr == null) {
      throw TokenWalletNotFoundException();
    } else {
      await proceedAsync(
        (port) => nativeLibraryInstance.bindings.free_token_wallet(
          port,
          _ptr!,
        ),
      );

      _ptr = null;
    }
  }
}
