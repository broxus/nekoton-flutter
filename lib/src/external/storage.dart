import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import '../models/pointed.dart';

class Storage implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;

  Storage._();

  static Future<Storage> create(Directory dir) async {
    final instance = Storage._();
    await instance._initialize(dir);
    return instance;
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Storage use after free');

        final ptr = NekotonFlutter.bindings.clone_storage_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) return;

        NekotonFlutter.bindings.free_storage_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _initialize(Directory dir) async {
    final result = executeSync(
      () => NekotonFlutter.bindings.create_storage(
        dir.path.toNativeUtf8().cast<Int8>(),
      ),
    );

    _ptr = Pointer.fromAddress(result).cast<Void>();
  }
}
