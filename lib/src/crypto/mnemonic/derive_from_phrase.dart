import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/crypto/mnemonic/models/keypair.dart';
import 'package:nekoton_flutter/src/crypto/mnemonic/models/mnemonic_type.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

Keypair deriveFromPhrase({
  required List<String> phrase,
  required MnemonicType mnemonicType,
}) {
  final phraseStr = phrase.join(' ');
  final mnemonicTypeStr = jsonEncode(mnemonicType);

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_derive_from_phrase(
          phraseStr.toNativeUtf8().cast<Char>(),
          mnemonicTypeStr.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as Map<String, dynamic>;
  final keypair = Keypair.fromJson(json);

  return keypair;
}
