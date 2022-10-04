import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/derived_key/derived_key_sign_params_by_account_id.dart';
import 'package:nekoton_flutter/src/crypto/derived_key/derived_key_sign_params_by_public_key.dart';
import 'package:nekoton_flutter/src/crypto/models/sign_input.dart';

part 'derived_key_sign_params.freezed.dart';
part 'derived_key_sign_params.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class DerivedKeySignParams with _$DerivedKeySignParams implements SignInput {
  const factory DerivedKeySignParams.byAccountId(DerivedKeySignParamsByAccountId data) =
      _ByAccountId;

  const factory DerivedKeySignParams.byPublicKey(DerivedKeySignParamsByPublicKey data) =
      _ByPublicKey;

  factory DerivedKeySignParams.fromJson(Map<String, dynamic> json) =>
      _$DerivedKeySignParamsFromJson(json);
}
