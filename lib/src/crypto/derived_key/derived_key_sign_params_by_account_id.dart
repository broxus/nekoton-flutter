import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/password_cache/password.dart';

part 'derived_key_sign_params_by_account_id.freezed.dart';
part 'derived_key_sign_params_by_account_id.g.dart';

@freezed
class DerivedKeySignParamsByAccountId with _$DerivedKeySignParamsByAccountId {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DerivedKeySignParamsByAccountId({
    required String masterKey,
    required int accountId,
    required Password password,
  }) = _DerivedKeySignParamsByAccountIdByAccountId;

  factory DerivedKeySignParamsByAccountId.fromJson(Map<String, dynamic> json) =>
      _$DerivedKeySignParamsByAccountIdFromJson(json);
}
