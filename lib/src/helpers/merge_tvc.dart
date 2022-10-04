import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

String mergeTvc({
  required String code,
  required String data,
}) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_merge_tvc(
          code.toNativeUtf8().cast<Char>(),
          data.toNativeUtf8().cast<Char>(),
        ),
  );

  final tvc = result as String;

  return tvc;
}
