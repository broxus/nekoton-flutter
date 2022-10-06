import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'models/execution_result.dart';

Pointer<Void> toPtrFromAddress(String address) =>
    NekotonFlutter.instance().bindings.nt_cstring_to_void_ptr(address.toNativeUtf8().cast<Char>());

dynamic executeSync(Pointer<Char> Function() function) {
  final ptr = function();
  final string = ptr.cast<Utf8>().toDartString();

  NekotonFlutter.instance().bindings.nt_free_cstring(ptr);

  final json = jsonDecode(string) as Map<String, dynamic>;
  final executionResult = ExecutionResult.fromJson(json);

  return executionResult.handle();
}

Future<dynamic> executeAsync(void Function(int port) function) async {
  final receivePort = ReceivePort();
  final completer = Completer<dynamic>();
  final st = StackTrace.current;

  receivePort.cast<String>().listen((data) {
    final ptr = toPtrFromAddress(data).cast<Char>();
    final string = ptr.cast<Utf8>().toDartString();

    NekotonFlutter.instance().bindings.nt_free_cstring(ptr);

    final json = jsonDecode(string) as Map<String, dynamic>;
    final executionResult = ExecutionResult.fromJson(json);

    try {
      final result = executionResult.handle();
      completer.complete(result);
    } catch (err) {
      completer.completeError(err, st);
    } finally {
      receivePort.close();
    }
  });

  function(receivePort.sendPort.nativePort);

  return completer.future;
}
