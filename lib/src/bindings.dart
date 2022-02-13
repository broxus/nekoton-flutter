import 'dart:ffi';
import 'dart:io';

import 'package:rxdart/subjects.dart';
import 'package:tuple/tuple.dart';

import 'bindings.g.dart';

Bindings? _bindings;

Bindings bindings() {
  if (_bindings != null) {
    return _bindings!;
  } else {
    throw Exception("Library isn't loaded");
  }
}

void loadNekotonLibrary() {
  final dylib = _dlOpenPlatformSpecific();
  final ptr = NativeApi.postCObject.cast<Void>();

  _bindings = Bindings(dylib)..store_post_cobject(ptr);
}

DynamicLibrary _dlOpenPlatformSpecific() {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libnekoton_flutter.so');
  } else if (Platform.isIOS) {
    return DynamicLibrary.process();
  } else {
    throw Exception('Invalid platform');
  }
}

final nekotonErrorsSubject = PublishSubject<Tuple2<Object, StackTrace>>();

final nekotonErrorsStream = nekotonErrorsSubject.stream;
