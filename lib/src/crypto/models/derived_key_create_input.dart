import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'create_key_input.dart';
import 'password.dart';

part 'derived_key_create_input.freezed.dart';
part 'derived_key_create_input.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class DerivedKeyCreateInput with _$DerivedKeyCreateInput implements CreateKeyInput {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory DerivedKeyCreateInput.import({
    String? keyName,
    required String phrase,
    required Password password,
  }) = _Import;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory DerivedKeyCreateInput.derive({
    String? keyName,
    required String masterKey,
    required int accountId,
    required Password password,
  }) = _Derive;

  factory DerivedKeyCreateInput.fromJson(Map<String, dynamic> json) => _$DerivedKeyCreateInputFromJson(json);
}
