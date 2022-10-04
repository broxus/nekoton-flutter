import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

String unpackStdSmcAddr({
  required String packed,
  required bool base64Url,
}) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_unpack_std_smc_addr(
          packed.toNativeUtf8().cast<Char>(),
          base64Url ? 1 : 0,
        ),
  );

  final unpacked = result as String;

  return unpacked;
}
