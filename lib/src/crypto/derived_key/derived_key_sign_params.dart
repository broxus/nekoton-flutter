import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/sign_input.dart';
import 'derived_key_sign_params_by_account_id.dart';
import 'derived_key_sign_params_by_public_key.dart';

part 'derived_key_sign_params.freezed.dart';
part 'derived_key_sign_params.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class DerivedKeySignParams with _$DerivedKeySignParams implements SignInput {
  const factory DerivedKeySignParams.byAccountId(DerivedKeySignParamsByAccountId data) =
      _DerivedKeySignParamsByAccountId;

  const factory DerivedKeySignParams.byPublicKey(DerivedKeySignParamsByPublicKey data) =
      _DerivedKeySignParamsByPublicKey;

  factory DerivedKeySignParams.fromJson(Map<String, dynamic> json) => _$DerivedKeySignParamsFromJson(json);
}
