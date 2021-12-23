import 'package:freezed_annotation/freezed_annotation.dart';

import 'password.dart';

part 'encrypted_key_password.freezed.dart';
part 'encrypted_key_password.g.dart';

@freezed
class EncryptedKeyPassword with _$EncryptedKeyPassword {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory EncryptedKeyPassword({
    required String publicKey,
    required Password password,
  }) = _EncryptedKeyPassword;

  factory EncryptedKeyPassword.fromJson(Map<String, dynamic> json) => _$EncryptedKeyPasswordFromJson(json);
}
