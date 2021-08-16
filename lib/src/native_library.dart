import 'dart:ffi';
import 'dart:io';

import 'bindings.g.dart';
import 'models/nekoton_exception.dart';

class NativeLibrary {
  static NativeLibrary? _instance;
  late final DynamicLibrary _dynamicLibrary;
  late final Bindings bindings;

  factory NativeLibrary.instance() => _instance ??= NativeLibrary._().._initialize();

  NativeLibrary._();

  void _initialize() {
    _dynamicLibrary = _dlOpenPlatformSpecific();
    bindings = Bindings(_dynamicLibrary);
  }

  DynamicLibrary _dlOpenPlatformSpecific() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open("libnekoton_flutter.so");
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else {
      throw DynamicLibraryException();
    }
  }
}
