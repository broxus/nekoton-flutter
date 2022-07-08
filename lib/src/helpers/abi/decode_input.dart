import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/decoded_input.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/method_name.dart';

DecodedInput? decodeInput({
  required String messageBody,
  required String contractAbi,
  required MethodName method,
  required bool internal,
}) {
  final methodStr = jsonEncode(method);

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_decode_input(
          messageBody.toNativeUtf8().cast<Char>(),
          contractAbi.toNativeUtf8().cast<Char>(),
          methodStr.toNativeUtf8().cast<Char>(),
          internal ? 1 : 0,
        ),
  );

  final json = result != null ? result as Map<String, dynamic> : null;
  final decodedInput = json != null ? DecodedInput.fromJson(json) : null;

  return decodedInput;
}
