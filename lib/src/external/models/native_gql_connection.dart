import 'dart:async';
import 'dart:ffi';

import 'package:nekoton_flutter/src/models/nekoton_exception.dart';

import '../../ffi_utils.dart';
import '../../nekoton.dart';

class NativeGqlConnection {
  Pointer<Void>? _ptr;

  NativeGqlConnection(this._ptr);

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) async {
    if (_ptr == null) {
      throw GqlConnectionNotFoundException();
    } else {
      return function(_ptr!);
    }
  }

  Future<void> free() async {
    if (_ptr == null) {
      throw GqlConnectionNotFoundException();
    } else {
      await proceedAsync(
        (port) => nativeLibraryInstance.bindings.free_gql_connection(
          port,
          _ptr!,
        ),
      );

      _ptr = null;
    }
  }
}
