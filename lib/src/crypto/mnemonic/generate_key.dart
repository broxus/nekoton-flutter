import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/crypto/mnemonic/models/generated_key.dart';
import 'package:nekoton_flutter/src/crypto/mnemonic/models/mnemonic_type.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

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
