import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/mnemonic/models/bip39_mnemonic_data.dart';

part 'mnemonic_type.freezed.dart';
part 'mnemonic_type.g.dart';

@Freezed(unionKey: 'type')
abstract class MnemonicType with _$MnemonicType {
  const factory MnemonicType.legacy() = _Legacy;

  const factory MnemonicType.bip39(Bip39MnemonicData data) = _Bip39;

  factory MnemonicType.fromJson(Map<String, dynamic> json) =>
      _$MnemonicTypeFromJson(json);
}
