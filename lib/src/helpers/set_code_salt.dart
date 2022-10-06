import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';

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

  final saltedCode = result as String;

  return saltedCode;
}
