import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';

String codeToTvc(String code) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_code_to_tvc(
          code.toNativeUtf8().cast<Char>(),
        ),
  );

  return result as String;
}
