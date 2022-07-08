import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/password_cache/password.dart';

part 'derived_key_update_params_change_password.freezed.dart';
part 'derived_key_update_params_change_password.g.dart';

@freezed
class DerivedKeyUpdateParamsChangePassword with _$DerivedKeyUpdateParamsChangePassword {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DerivedKeyUpdateParamsChangePassword({
    required String masterKey,
    required Password oldPassword,
    required Password newPassword,
  }) = _DerivedKeyUpdateParamsChangePasswordChangePassword;

  factory DerivedKeyUpdateParamsChangePassword.fromJson(Map<String, dynamic> json) =>
      _$DerivedKeyUpdateParamsChangePasswordFromJson(json);
}
