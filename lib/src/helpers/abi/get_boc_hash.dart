import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';

String getBocHash(String boc) {
  final result = executeSync(
    () => NekotonFlutter.bindings.nt_get_boc_hash(
      boc.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = cStringToDart(result);

  return string;
}
