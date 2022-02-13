import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import 'models/generated_key.dart';
import 'models/keypair.dart';
import 'models/mnemonic_type.dart';

GeneratedKey generateKey(MnemonicType mnemonicType) {
  final mnemonicTypeStr = jsonEncode(mnemonicType);

  final result = executeSync(() => bindings().generate_key(mnemonicTypeStr.toNativeUtf8().cast<Int8>()));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final key = GeneratedKey.fromJson(json);

  return key;
}

List<String> getHints(String input) {
  final result = executeSync(() => bindings().get_hints(input.toNativeUtf8().cast<Int8>()));

  final string = cStringToDart(result);
  final list = jsonDecode(string) as List;

  return list.cast<String>();
}

Keypair deriveFromPhrase({
  required List<String> phrase,
  required MnemonicType mnemonicType,
}) {
  final phraseStr = phrase.join(' ');
  final mnemonicTypeStr = jsonEncode(mnemonicType);

  final result = executeSync(
    () => bindings().derive_from_phrase(
      phraseStr.toNativeUtf8().cast<Int8>(),
      mnemonicTypeStr.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final keypair = Keypair.fromJson(json);

  return keypair;
}
