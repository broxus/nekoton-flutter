import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/execution_output.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/tokens_object.dart';

ExecutionOutput runLocal({
  required String accountStuffBoc,
  required String contractAbi,
  required String method,
  required TokensObject input,
  required bool responsible,
}) {
  final inputStr = jsonEncode(input);

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_run_local(
          accountStuffBoc.toNativeUtf8().cast<Char>(),
          contractAbi.toNativeUtf8().cast<Char>(),
          method.toNativeUtf8().cast<Char>(),
          inputStr.toNativeUtf8().cast<Char>(),
          responsible ? 1 : 0,
        ),
  );

  final json = result as Map<String, dynamic>;
  final executionOutput = ExecutionOutput.fromJson(json);

  return executionOutput;
}
