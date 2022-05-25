import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import 'models/tokens_object.dart';

String encodeInternalInput({
  required String contractAbi,
  required String method,
  required TokensObject input,
}) {
  final inputStr = jsonEncode(input);

  final result = executeSync(
    () => NekotonFlutter.bindings.nt_encode_internal_input(
      contractAbi.toNativeUtf8().cast<Char>(),
      method.toNativeUtf8().cast<Char>(),
      inputStr.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = cStringToDart(result);

  return string;
}
