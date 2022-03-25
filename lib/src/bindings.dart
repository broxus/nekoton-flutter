import 'dart:ffi';
import 'dart:io';

import 'package:logger/logger.dart';

import 'bindings.g.dart';

abstract class NekotonFlutter {
  static Logger? logger;
  static Bindings? _bindings;

  static void initialize([Logger? logger]) {
    NekotonFlutter.logger = logger;

    final dylib = _dlOpenPlatformSpecific();
    final ptr = NativeApi.postCObject.cast<Void>();

    _bindings = Bindings(dylib)..store_post_cobject(ptr);
  }

  static Bindings get bindings {
    if (_bindings != null) {
      return _bindings!;
    } else {
      throw Exception("Library isn't loaded");
    }
  }

  static DynamicLibrary _dlOpenPlatformSpecific() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libnekoton_flutter.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else {
      throw Exception('Invalid platform');
    }
  }
}
