import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/nekoton.dart';

import '../../ffi_utils.dart';
import 'models/generated_key.dart';
import 'models/keypair.dart';
import 'models/mnemonic_type.dart';

GeneratedKey generateKey(MnemonicType mnemonicType) {
  final mnemonicTypeStr = jsonEncode(mnemonicType);

  final result =
      proceedSync(() => nativeLibraryInstance.bindings.generate_key(mnemonicTypeStr.toNativeUtf8().cast<Int8>()));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final key = GeneratedKey.fromJson(json);

  return key;
}

List<String> getHints(String input) {
  final result = proceedSync(() => nativeLibraryInstance.bindings.get_hints(input.toNativeUtf8().cast<Int8>()));

  final string = cStringToDart(result);
  final list = jsonDecode(string) as List;

  return list.cast<String>();
}

Keypair deriveFromPhrase({
  required List<String> phrase,
  required MnemonicType mnemonicType,
}) {
  final phraseStr = phrase.join(" ");
  final mnemonicTypeStr = jsonEncode(mnemonicType);

  final result = proceedSync(() => nativeLibraryInstance.bindings.derive_from_phrase(
        phraseStr.toNativeUtf8().cast<Int8>(),
        mnemonicTypeStr.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final keypair = Keypair.fromJson(json);

  return keypair;
}
