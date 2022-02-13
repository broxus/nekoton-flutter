import 'package:freezed_annotation/freezed_annotation.dart';

import '../mnemonic/models/mnemonic_type.dart';
import 'create_key_input.dart';
import 'password.dart';

part 'encrypted_key_create_input.freezed.dart';
part 'encrypted_key_create_input.g.dart';

@freezed
class EncryptedKeyCreateInput with _$EncryptedKeyCreateInput implements CreateKeyInput {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory EncryptedKeyCreateInput({
    String? name,
    required String phrase,
    required MnemonicType mnemonicType,
    required Password password,
  }) = _EncryptedKeyCreateInput;

  factory EncryptedKeyCreateInput.fromJson(Map<String, dynamic> json) => _$EncryptedKeyCreateInputFromJson(json);
}
