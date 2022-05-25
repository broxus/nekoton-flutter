import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import 'models/decoded_output.dart';
import 'models/method_name.dart';

DecodedOutput? decodeOutput({
  required String messageBody,
  required String contractAbi,
  required MethodName method,
}) {
  final methodStr = jsonEncode(method);

  final result = executeSync(
    () => NekotonFlutter.bindings.nt_decode_output(
      messageBody.toNativeUtf8().cast<Char>(),
      contractAbi.toNativeUtf8().cast<Char>(),
      methodStr.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = optionalCStringToDart(result);
  final json = string != null ? jsonDecode(string) as Map<String, dynamic> : null;
  final decodedOutput = json != null ? DecodedOutput.fromJson(json) : null;

  return decodedOutput;
}
