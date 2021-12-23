import 'package:freezed_annotation/freezed_annotation.dart';

import 'password.dart';

part 'derived_key_update_params.freezed.dart';
part 'derived_key_update_params.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class DerivedKeyUpdateParams with _$DerivedKeyUpdateParams {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DerivedKeyUpdateParams.renameKey({
    required String masterKey,
    required String publicKey,
    required String name,
  }) = _RenameKey;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory DerivedKeyUpdateParams.changePassword({
    required String masterKey,
    required Password oldPassword,
    required Password newPassword,
  }) = _ChangePassword;

  factory DerivedKeyUpdateParams.fromJson(Map<String, dynamic> json) => _$DerivedKeyUpdateParamsFromJson(json);
}
