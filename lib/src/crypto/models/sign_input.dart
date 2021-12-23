import 'package:freezed_annotation/freezed_annotation.dart';

import 'derived_key_sign_params.dart';
import 'encrypted_key_password.dart';

part 'sign_input.freezed.dart';

@freezed
class SignInput with _$SignInput {
  const factory SignInput.derivedKeySignParams(
    DerivedKeySignParams derivedKeySignParams,
  ) = _DerivedKeySignParams;

  const factory SignInput.encryptedKeyPassword(
    EncryptedKeyPassword encryptedKeyPassword,
  ) = _EncryptedKeyPassword;
}
