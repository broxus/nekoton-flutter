import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/decoded_output.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/method_name.dart';

DecodedOutput? decodeOutput({
  required String messageBody,
  required String contractAbi,
  required MethodName method,
}) {
  final methodStr = method != null ? jsonEncode(method) : null;

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_decode_output(
          messageBody.toNativeUtf8().cast<Char>(),
          contractAbi.toNativeUtf8().cast<Char>(),
          methodStr?.toNativeUtf8().cast<Char>() ?? nullptr,
        ),
  );

  final json = result as Map<String, dynamic>?;
  final decodedOutput = json != null ? DecodedOutput.fromJson(json) : null;

  return decodedOutput;
}
