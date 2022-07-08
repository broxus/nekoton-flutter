import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

String extractPublicKey(String boc) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_extract_public_key(
          boc.toNativeUtf8().cast<Char>(),
        ),
  );

  return result as String;
}
