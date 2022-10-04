import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

String setCodeSalt({
  required String code,
  required String salt,
}) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_set_code_salt(
          code.toNativeUtf8().cast<Char>(),
          salt.toNativeUtf8().cast<Char>(),
        ),
  );

  final salted = result as String;

  return salted;
}
