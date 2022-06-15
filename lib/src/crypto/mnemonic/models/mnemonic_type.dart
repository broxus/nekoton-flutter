import 'package:freezed_annotation/freezed_annotation.dart';

part 'mnemonic_type.freezed.dart';
part 'mnemonic_type.g.dart';

@Freezed(unionKey: 'type')
class MnemonicType with _$MnemonicType {
  const factory MnemonicType.legacy() = _MnemonicTypeLegacy;

  const factory MnemonicType.labs(int data) = _MnemonicTypeLabs;

  factory MnemonicType.fromJson(Map<String, dynamic> json) => _$MnemonicTypeFromJson(json);
}
