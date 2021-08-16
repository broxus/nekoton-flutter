import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'password.dart';
import 'update_key_input.dart';

part 'encrypted_key_update_params.freezed.dart';
part 'encrypted_key_update_params.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class EncryptedKeyUpdateParams with _$EncryptedKeyUpdateParams implements UpdateKeyInput {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory EncryptedKeyUpdateParams.rename({
    required String publicKey,
    required String name,
  }) = _Rename;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory EncryptedKeyUpdateParams.changePassword({
    required String publicKey,
    required Password oldPassword,
    required Password newPassword,
  }) = _ChangePassword;

  factory EncryptedKeyUpdateParams.fromJson(Map<String, dynamic> json) => _$EncryptedKeyUpdateParamsFromJson(json);
}