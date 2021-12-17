import 'package:freezed_annotation/freezed_annotation.dart';

import 'mnemonic_type.dart';

part 'generated_key.freezed.dart';
part 'generated_key.g.dart';

@freezed
class GeneratedKey with _$GeneratedKey {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory GeneratedKey({
    required List<String> words,
    required MnemonicType mnemonicType,
  }) = _GeneratedKey;

  factory GeneratedKey.fromJson(Map<String, dynamic> json) => _$GeneratedKeyFromJson(json);
}
