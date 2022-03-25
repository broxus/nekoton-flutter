import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'models/execution_result.dart';

int executeSync(Pointer<Void> Function() function) {
  final ptr = function();
  final executionResult = ptr.cast<ExecutionResult>().ref;

  try {
    return executionResult.handle();
  } finally {
    NekotonFlutter.bindings.free_execution_result(ptr);
  }
}

Future<int> executeAsync(void Function(int port) function) async {
  final receivePort = ReceivePort();
  final completer = Completer<int>();
  final st = StackTrace.current;

  receivePort.cast<int>().listen((data) {
    final ptr = Pointer.fromAddress(data).cast<Void>();
    final executionResult = ptr.cast<ExecutionResult>().ref;

    try {
      final result = executionResult.handle();
      completer.complete(result);
    } catch (err) {
      completer.completeError(err, st);
    } finally {
      NekotonFlutter.bindings.free_execution_result(ptr);
      receivePort.close();
    }
  });

  function(receivePort.sendPort.nativePort);

  return completer.future;
}

String cStringToDart(int address) {
  final ptr = Pointer.fromAddress(address).cast<Int8>();

  final string = ptr.cast<Utf8>().toDartString();

  NekotonFlutter.bindings.free_cstring(ptr);

  return string;
}
