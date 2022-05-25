import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';

String extractPublicKey(String boc) {
  final result = executeSync(
    () => NekotonFlutter.bindings.nt_extract_public_key(
      boc.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = cStringToDart(result);

  return string;
}
