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
    () => NekotonFlutter.bindings.nt_generate_key(
      mnemonicTypeStr.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final key = GeneratedKey.fromJson(json);

  return key;
}
