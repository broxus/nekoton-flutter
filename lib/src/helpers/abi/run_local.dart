import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import 'models/execution_output.dart';
import 'models/tokens_object.dart';

ExecutionOutput runLocal({
  required String accountStuffBoc,
  required String contractAbi,
  required String method,
  required TokensObject input,
  required bool responsible,
}) {
  final inputStr = jsonEncode(input);

  final result = executeSync(
    () => NekotonFlutter.bindings.nt_run_local(
      accountStuffBoc.toNativeUtf8().cast<Char>(),
      contractAbi.toNativeUtf8().cast<Char>(),
      method.toNativeUtf8().cast<Char>(),
      inputStr.toNativeUtf8().cast<Char>(),
      responsible ? 1 : 0,
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final executionOutput = ExecutionOutput.fromJson(json);

  return executionOutput;
}
