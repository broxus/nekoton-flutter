import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import 'models/keypair.dart';
import 'models/mnemonic_type.dart';

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
