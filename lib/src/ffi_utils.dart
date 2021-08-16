import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'models/native_result.dart';
import 'native_library.dart';

int proceedSync(Pointer<Void> Function() function) {
  final nativeLibrary = NativeLibrary.instance();

  final ptr = function();
  final nativeResult = ptr.cast<NativeResult>().ref;

  try {
    return nativeResult.handle();
  } finally {
    nativeLibrary.bindings.free_native_result(ptr);
  }
}

Future<int> proceedAsync(void Function(int port) function) async {
  final receivePort = ReceivePort();
  final completer = Completer<int>();

  receivePort.listen((data) {
    if (data is! int) {
      return;
    }

    final nativeLibrary = NativeLibrary.instance();

    final ptr = Pointer.fromAddress(data).cast<Void>();
    final nativeResult = ptr.cast<NativeResult>().ref;

    try {
      final result = nativeResult.handle();
      completer.complete(result);
    } catch (err, st) {
      completer.completeError(err, st);
    }

    nativeLibrary.bindings.free_native_result(ptr);
    receivePort.close();
  });

  function(receivePort.sendPort.nativePort);

  return completer.future;
}

String cStringToDart(int address) {
  final nativeLibrary = NativeLibrary.instance();

  final ptr = Pointer.fromAddress(address).cast<Int8>();
  final string = ptr.cast<Utf8>().toDartString();

  nativeLibrary.bindings.free_cstring(ptr);

  return string;
}
