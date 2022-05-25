import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';

String unpackStdSmcAddr({
  required String packed,
  required bool base64Url,
}) {
  final result = executeSync(
    () => NekotonFlutter.bindings.nt_unpack_std_smc_addr(
      packed.toNativeUtf8().cast<Char>(),
      base64Url ? 1 : 0,
    ),
  );

  final string = cStringToDart(result);

  return string;
}
