import 'package:freezed_annotation/freezed_annotation.dart';

import 'derived_key_create_input.dart';
import 'encrypted_key_create_input.dart';

part 'create_key_input.freezed.dart';

@freezed
class CreateKeyInput with _$CreateKeyInput {
  const factory CreateKeyInput.derivedKeyCreateInput(
    DerivedKeyCreateInput derivedKeyCreateInput,
  ) = _DerivedKeyCreateInput;

  const factory CreateKeyInput.encryptedKeyCreateInput(
    EncryptedKeyCreateInput encryptedKeyCreateInput,
  ) = _EncryptedKeyCreateInput;
}
