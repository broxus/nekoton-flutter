import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import '../models/pointed.dart';

class Storage implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;

  Storage._();

  static Future<Storage> create() async {
    final storage = Storage._();
    await storage._initialize();
    return storage;
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Storage use after free');

        final ptr = bindings().clone_storage_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Storage use after free');

        bindings().free_storage_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    final result = executeSync(
      () => bindings().create_storage(
        dir.path.toNativeUtf8().cast<Int8>(),
      ),
    );

    _ptr = Pointer.fromAddress(result).cast<Void>();
  }
}
