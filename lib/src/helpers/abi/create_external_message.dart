import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../crypto/unsigned_message.dart';
import '../../ffi_utils.dart';
import 'models/tokens_object.dart';

UnsignedMessage createExternalMessage({
  required String dst,
  required String contractAbi,
  required String method,
  String? stateInit,
  required TokensObject input,
  required String publicKey,
  required int timeout,
}) {
  final inputStr = jsonEncode(input);

  final result = executeSync(
    () => NekotonFlutter.bindings.nt_create_external_message(
      dst.toNativeUtf8().cast<Char>(),
      contractAbi.toNativeUtf8().cast<Char>(),
      method.toNativeUtf8().cast<Char>(),
      stateInit?.toNativeUtf8().cast<Char>() ?? nullptr,
      inputStr.toNativeUtf8().cast<Char>(),
      publicKey.toNativeUtf8().cast<Char>(),
      timeout,
    ),
  );

  final unsignedMessage = UnsignedMessage(Pointer.fromAddress(result).cast<Void>());

  return unsignedMessage;
}
