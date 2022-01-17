import 'dart:async';
import 'dart:ffi';

import '../../../ffi_utils.dart';
import '../../../models/nekoton_exception.dart';
import '../../../nekoton.dart';

class NativeAccountsStorage {
  Pointer<Void>? _ptr;

  NativeAccountsStorage(this._ptr);

  bool get isNull => _ptr == null;

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) async {
    if (_ptr == null) {
      throw AccountStorageNotFoundException();
    } else {
      return function(_ptr!);
    }
  }

  Future<void> free() async {
    if (_ptr == null) {
      throw AccountStorageNotFoundException();
    } else {
      final ptr = _ptr;
      _ptr = null;

      await proceedAsync(
        (port) => nativeLibraryInstance.bindings.free_accounts_storage(
          port,
          ptr!,
        ),
      );
    }
  }
}
