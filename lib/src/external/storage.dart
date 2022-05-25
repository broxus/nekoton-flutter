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

  Future<String?> get(String key) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.bindings.nt_storage_get(
        port,
        ptr,
        key.toNativeUtf8().cast<Char>(),
      ),
    );

    final value = optionalCStringToDart(result);

    return value;
  }

  Future<void> set({
    required String key,
    required String value,
  }) async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => NekotonFlutter.bindings.nt_storage_set(
        port,
        ptr,
        key.toNativeUtf8().cast<Char>(),
        value.toNativeUtf8().cast<Char>(),
      ),
    );
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Storage use after free');

        final ptr = NekotonFlutter.bindings.nt_storage_clone_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) return;

        NekotonFlutter.bindings.nt_storage_free_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _initialize(Directory dir) => _lock.synchronized(() async {
        final result = executeSync(
          () => NekotonFlutter.bindings.nt_storage_create(
            dir.path.toNativeUtf8().cast<Char>(),
          ),
        );

        _ptr = Pointer.fromAddress(result).cast<Void>();
      });
}
