import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:synchronized/synchronized.dart';

import 'bindings.g.dart';
import 'models/nekoton_exception.dart';
import 'nekoton.dart';

class NativeLibrary {
  static const _methodChannel = MethodChannel('nekoton_native_library');
  static NativeLibrary? _instance;
  static final _lock = Lock();
  late final DynamicLibrary _dynamicLibrary;
  late final Bindings bindings;

  NativeLibrary._();

  static Future<NativeLibrary> getInstance() => _lock.synchronized<NativeLibrary>(() async {
        if (_instance == null) {
          final instance = NativeLibrary._();
          await instance._initialize();
          _instance = instance;
        }

        return _instance!;
      });

  Future<void> _initialize() async {
    _dynamicLibrary = await _dlOpenPlatformSpecific();
    bindings = Bindings(_dynamicLibrary)..store_post_cobject(Pointer.fromAddress(NativeApi.postCObject.address));
  }

  Future<DynamicLibrary> _dlOpenPlatformSpecific() async {
    if (Platform.isAndroid) {
      return _dlOpenAndroidPlatform();
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else {
      throw DynamicLibraryException();
    }
  }

  Future<DynamicLibrary> _dlOpenAndroidPlatform() async {
    try {
      try {
        return DynamicLibrary.open('libnekoton_flutter.so');
      } catch (err, st) {
        nekotonLogger?.e(err, err, st);

        try {
          final nativeLibraryDir = (await _methodChannel.invokeMethod<String>('getNativeLibraryDir'))!;

          return DynamicLibrary.open('$nativeLibraryDir/libnekoton_flutter.so');
        } catch (err, st) {
          nekotonLogger?.e(err, err, st);

          final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();
          final endOfAppId = max(appIdAsBytes.indexOf(0), 0);
          final appId = String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId));

          return DynamicLibrary.open('/data/data/$appId/lib/libnekoton_flutter.so');
        }
      }
    } catch (err, st) {
      nekotonLogger?.e(err, err, st);

      try {
        await _methodChannel.invokeMethod('loadLibrary', 'nekoton_flutter');

        return DynamicLibrary.open('libnekoton_flutter.so');
      } catch (err, st) {
        nekotonLogger?.e(err, err, st);
        rethrow;
      }
    }
  }
}
