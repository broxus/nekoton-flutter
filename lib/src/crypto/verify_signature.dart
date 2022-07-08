import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

bool verifySignature({
  required String publicKey,
  required String dataHash,
  required String signature,
}) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_verify_signature(
          publicKey.toNativeUtf8().cast<Char>(),
          dataHash.toNativeUtf8().cast<Char>(),
          signature.toNativeUtf8().cast<Char>(),
        ),
  );

  final isValid = result != 0;

  return isValid;
}
