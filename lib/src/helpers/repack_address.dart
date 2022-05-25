import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';

String repackAddress(String address) {
  final result = executeSync(
    () => NekotonFlutter.bindings.nt_repack_address(
      address.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = cStringToDart(result);

  return string;
}
