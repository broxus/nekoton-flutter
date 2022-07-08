import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/models/get_public_keys.dart';
import 'package:nekoton_flutter/src/crypto/password_cache/password.dart';

part 'derived_key_get_public_keys.freezed.dart';
part 'derived_key_get_public_keys.g.dart';

@freezed
class DerivedKeyGetPublicKeys with _$DerivedKeyGetPublicKeys implements GetPublicKeys {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DerivedKeyGetPublicKeys({
    required String masterKey,
    required Password password,
    required int limit,
    required int offset,
  }) = _DerivedKeyGetPublicKeysRename;

  factory DerivedKeyGetPublicKeys.fromJson(Map<String, dynamic> json) =>
      _$DerivedKeyGetPublicKeysFromJson(json);
}
