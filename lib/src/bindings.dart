import 'dart:ffi';
import 'dart:io';

import 'package:nekoton_flutter/src/bindings.ffigen.dart';

class NekotonFlutter {
  static NekotonFlutter? _instance;
  late final Bindings _bindings;

  NekotonFlutter._() {
    _bindings = Bindings(_dlOpenPlatformSpecific())
      ..nt_store_dart_post_cobject(NativeApi.postCObject.cast<Void>());
  }

  factory NekotonFlutter.instance() => _instance ??= NekotonFlutter._();

  Bindings get bindings => _bindings;

  DynamicLibrary _dlOpenPlatformSpecific() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libnekoton_flutter.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libnekoton_flutter.so');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.process();
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('nekoton_flutter.dll');
    } else {
      throw UnsupportedError('Invalid platform');
    }
  }
}
