import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/tokens_object.dart';

String encodeInternalInput({
  required String contractAbi,
  required String method,
  required TokensObject input,
}) {
  final inputStr = jsonEncode(input);

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_encode_internal_input(
          contractAbi.toNativeUtf8().cast<Char>(),
          method.toNativeUtf8().cast<Char>(),
          inputStr.toNativeUtf8().cast<Char>(),
        ),
  );

  final encodedInput = result as String;

  return encodedInput;
}
