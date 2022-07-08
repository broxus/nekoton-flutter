import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/password_cache/password.dart';

part 'encrypted_key_update_params_change_password.freezed.dart';
part 'encrypted_key_update_params_change_password.g.dart';

@freezed
class EncryptedKeyUpdateParamsChangePassword with _$EncryptedKeyUpdateParamsChangePassword {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory EncryptedKeyUpdateParamsChangePassword({
    required String publicKey,
    required Password oldPassword,
    required Password newPassword,
  }) = _EncryptedKeyUpdateParamsChangePasswordChangePassword;

  factory EncryptedKeyUpdateParamsChangePassword.fromJson(Map<String, dynamic> json) =>
      _$EncryptedKeyUpdateParamsChangePasswordFromJson(json);
}
