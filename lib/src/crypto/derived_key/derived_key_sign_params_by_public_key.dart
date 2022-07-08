import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/password_cache/password.dart';

part 'derived_key_sign_params_by_public_key.freezed.dart';
part 'derived_key_sign_params_by_public_key.g.dart';

@freezed
class DerivedKeySignParamsByPublicKey with _$DerivedKeySignParamsByPublicKey {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DerivedKeySignParamsByPublicKey({
    required String masterKey,
    required String publicKey,
    required Password password,
  }) = _DerivedKeySignParamsByPublicKeyByPublicKey;

  factory DerivedKeySignParamsByPublicKey.fromJson(Map<String, dynamic> json) =>
      _$DerivedKeySignParamsByPublicKeyFromJson(json);
}
