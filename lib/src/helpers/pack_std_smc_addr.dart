import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

String packStdSmcAddr({
  required bool base64Url,
  required String addr,
  required bool bounceable,
}) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_pack_std_smc_addr(
          base64Url ? 1 : 0,
          addr.toNativeUtf8().cast<Char>(),
          bounceable ? 1 : 0,
        ),
  );

  final packed = result as String;

  return packed;
}
