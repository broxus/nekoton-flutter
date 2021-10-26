import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../ffi_utils.dart';
import '../nekoton.dart';
import 'models/native_storage.dart';
import 'models/storage_request.dart';
import 'models/storage_request_type.dart';

class Storage {
  static const _storageBoxName = 'nekoton_storage';
  static Storage? _instance;
  late final Box<String> _box;
  final _receivePort = ReceivePort();
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
    await Hive.initFlutter();
    _box = await Hive.openBox(_storageBoxName);

    _receivePort.listen(_storageListener);

    final result = proceedSync(() => nativeLibraryInstance.bindings.get_storage(_receivePort.sendPort.nativePort));
    final ptr = Pointer.fromAddress(result).cast<Void>();
    nativeStorage = NativeStorage(ptr);
  }

  Future<void> _storageListener(dynamic data) async {
    try {
      if (data is! String) {
        return;
      }

      final json = jsonDecode(data) as Map<String, dynamic>;
      final request = StorageRequest.fromJson(json);
      final tx = request.tx.toString();

      Pointer<Int8> value = Pointer.fromAddress(0).cast<Int8>();
      bool isSuccessful = false;

      try {
        switch (request.requestType) {
          case StorageRequestType.get:
            final result = _box.get(request.key);
            if (result != null) {
              value = result.toNativeUtf8().cast<Int8>();
            }
            break;
          case StorageRequestType.set:
            await _box.put(request.key, request.value!);
            break;
          case StorageRequestType.remove:
            await _box.delete(request.key);
            break;
        }

        isSuccessful = true;
      } catch (err) {
        value = err.toString().toNativeUtf8().cast<Int8>();
      }

      nativeLibraryInstance.bindings.resolve_storage_request(
        tx.toNativeUtf8().cast<Int8>(),
        isSuccessful ? 1 : 0,
        value,
      );
    } catch (err, st) {
      nekotonLogger?.e(err, err, st);
    }
  }
}
