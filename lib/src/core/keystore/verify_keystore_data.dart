import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';

bool verifyKeystoreData(String data) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_keystore_verify_data(
          data.toNativeUtf8().cast<Char>(),
        ),
  );

  final isValid = result != 0;

  return isValid;
}
