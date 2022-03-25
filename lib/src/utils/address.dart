import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';

String packStdSmcAddr({
  required bool base64Url,
  required String addr,
  required bool bounceable,
}) {
  final result = executeSync(
    () => NekotonFlutter.bindings.pack_std_smc_addr(
      base64Url ? 1 : 0,
      addr.toNativeUtf8().cast<Int8>(),
      bounceable ? 1 : 0,
    ),
  );

  final string = cStringToDart(result);

  return string;
}

String unpackStdSmcAddr({
  required String packed,
  required bool base64Url,
}) {
  final result = executeSync(
    () => NekotonFlutter.bindings.unpack_std_smc_addr(
      packed.toNativeUtf8().cast<Int8>(),
      base64Url ? 1 : 0,
    ),
  );

  final string = cStringToDart(result);

  return string;
}

bool validateAddress(String address) {
  final result = executeSync(
    () => NekotonFlutter.bindings.validate_address(
      address.toNativeUtf8().cast<Int8>(),
    ),
  );

  final isValid = result != 0;

  return isValid;
}

String repackAddress(String address) {
  final result = executeSync(
    () => NekotonFlutter.bindings.repack_address(
      address.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);

  return string;
}
