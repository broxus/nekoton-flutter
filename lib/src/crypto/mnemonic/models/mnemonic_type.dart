import 'package:freezed_annotation/freezed_annotation.dart';

part 'mnemonic_type.freezed.dart';
part 'mnemonic_type.g.dart';

@Freezed(unionKey: 'type')
class MnemonicType with _$MnemonicType {
  const factory MnemonicType.legacy() = _Legacy;

  const factory MnemonicType.labs(int data) = _Labs;

  factory MnemonicType.fromJson(Map<String, dynamic> json) => _$MnemonicTypeFromJson(json);
}
