import 'package:freezed_annotation/freezed_annotation.dart';

import 'password.dart';
import 'sign_input.dart';

part 'derived_key_sign_params.freezed.dart';
part 'derived_key_sign_params.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class DerivedKeySignParams with _$DerivedKeySignParams implements SignInput {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory DerivedKeySignParams.byAccountId({
    required String masterKey,
    required int accountId,
    required Password password,
  }) = _ByAccountId;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory DerivedKeySignParams.byPublicKey({
    required String masterKey,
    required String publicKey,
    required Password password,
  }) = _ByPublicKey;

  factory DerivedKeySignParams.fromJson(Map<String, dynamic> json) => _$DerivedKeySignParamsFromJson(json);
}
