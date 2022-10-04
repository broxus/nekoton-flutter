import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/crypto/unsigned_message.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/tokens_object.dart';

Future<UnsignedMessage> createExternalMessage({
  required String dst,
  required String contractAbi,
  required String method,
  String? stateInit,
  required TokensObject input,
  required String publicKey,
  required int timeout,
}) async {
  final inputStr = jsonEncode(input);

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_create_external_message(
          dst.toNativeUtf8().cast<Char>(),
          contractAbi.toNativeUtf8().cast<Char>(),
          method.toNativeUtf8().cast<Char>(),
          stateInit?.toNativeUtf8().cast<Char>() ?? nullptr,
          inputStr.toNativeUtf8().cast<Char>(),
          publicKey.toNativeUtf8().cast<Char>(),
          timeout,
        ),
  );

  final unsignedMessage = await UnsignedMessage.create(toPtrFromAddress(result as String));

  return unsignedMessage;
}
