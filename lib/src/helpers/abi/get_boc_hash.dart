import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

String getBocHash(String boc) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_get_boc_hash(
          boc.toNativeUtf8().cast<Char>(),
        ),
  );

  final hash = result as String;

  return hash;
}
