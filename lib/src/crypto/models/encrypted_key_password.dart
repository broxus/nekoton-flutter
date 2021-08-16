import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'export_key_input.dart';
import 'password.dart';
import 'sign_input.dart';

part 'encrypted_key_password.freezed.dart';
part 'encrypted_key_password.g.dart';

@freezed
class EncryptedKeyPassword with _$EncryptedKeyPassword implements SignInput, ExportKeyInput {
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
