import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

bool validateAddress(String address) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_validate_address(
          address.toNativeUtf8().cast<Char>(),
        ),
  );

  final isValid = result != 0;

  return isValid;
}
