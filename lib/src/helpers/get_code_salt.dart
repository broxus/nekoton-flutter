import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';

String? getCodeSalt(String code) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_get_code_salt(
          code.toNativeUtf8().cast<Char>(),
        ),
  );

  final salt = result as String?;

  return salt;
}
