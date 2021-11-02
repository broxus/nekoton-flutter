import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';

import '../ffi_utils.dart';
import '../nekoton.dart';
import 'models/native_storage.dart';

class Storage {
  static Storage? _instance;
  late final NativeStorage nativeStorage;

  Storage._();

  static Future<Storage> getInstance() async {
    if (_instance == null) {
      final instance = Storage._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Future<void> free() => nativeStorage.free();

  Future<void> _initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    final result = proceedSync(
      () => nativeLibraryInstance.bindings.get_storage(
        dir.path.toNativeUtf8().cast<Int8>(),
      ),
    );
    final ptr = Pointer.fromAddress(result).cast<Void>();
    nativeStorage = NativeStorage(ptr);
  }
}
