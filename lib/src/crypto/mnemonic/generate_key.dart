import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import 'models/generated_key.dart';
import 'models/mnemonic_type.dart';

GeneratedKey generateKey(MnemonicType mnemonicType) {
  final mnemonicTypeStr = jsonEncode(mnemonicType);

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_generate_key(
          mnemonicTypeStr.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as Map<String, dynamic>;
  final key = GeneratedKey.fromJson(json);

  return key;
}
