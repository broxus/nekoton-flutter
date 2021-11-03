import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mnemonic_type.freezed.dart';
part 'mnemonic_type.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class MnemonicType with _$MnemonicType {
  const factory MnemonicType.legacy() = _Legacy;

  const factory MnemonicType.labs({
    required int id,
  }) = _Labs;

  factory MnemonicType.fromJson(Map<String, dynamic> json) => _$MnemonicTypeFromJson(json);
}
