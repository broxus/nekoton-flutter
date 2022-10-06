import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';

bool verifyAccountsStorageData(String data) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_accounts_storage_verify_data(
          data.toNativeUtf8().cast<Char>(),
        ),
  );

  final isValid = result != 0;

  return isValid;
}
