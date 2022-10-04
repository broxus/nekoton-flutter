import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

String repackAddress(String address) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_repack_address(
          address.toNativeUtf8().cast<Char>(),
        ),
  );

  final repacked = result as String;

  return repacked;
}
