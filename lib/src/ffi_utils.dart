import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'models/native_result.dart';
import 'models/nekoton_exception.dart';
import 'nekoton.dart';

int proceedSync(Pointer<Void> Function() function) {
  final ptr = function();
  final nativeResult = ptr.cast<NativeResult>().ref;

  try {
    return nativeResult.handle();
  } finally {
    nativeLibraryInstance.bindings.free_native_result(ptr);
  }
}

Future<int> proceedAsync(void Function(int port) function) async {
  final receivePort = ReceivePort();
  final completer = Completer<int>();
  final st = StackTrace.current;

  receivePort.listen((data) {
    if (data is! int) {
      completer.completeError(IncorrectDataFormatException());
      receivePort.close();
      return;
    }

    final ptr = Pointer.fromAddress(data).cast<Void>();
    final nativeResult = ptr.cast<NativeResult>().ref;

    try {
      final result = nativeResult.handle();
      completer.complete(result);
    } catch (err) {
      completer.completeError(err, st);
    } finally {
      nativeLibraryInstance.bindings.free_native_result(ptr);
      receivePort.close();
    }
  });

  function(receivePort.sendPort.nativePort);

  return completer.future;
}

String cStringToDart(int address) {
  final ptr = Pointer.fromAddress(address).cast<Int8>();
  final string = ptr.cast<Utf8>().toDartString();

  nativeLibraryInstance.bindings.free_cstring(ptr);

  return string;
}
