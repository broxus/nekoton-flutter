import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/derived_key/derived_key_update_params_change_password.dart';
import 'package:nekoton_flutter/src/crypto/derived_key/derived_key_update_params_rename_key.dart';
import 'package:nekoton_flutter/src/crypto/models/update_key_input.dart';

part 'derived_key_update_params.freezed.dart';
part 'derived_key_update_params.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class DerivedKeyUpdateParams with _$DerivedKeyUpdateParams implements UpdateKeyInput {
  const factory DerivedKeyUpdateParams.renameKey(DerivedKeyUpdateParamsRenameKey data) = _RenameKey;

  const factory DerivedKeyUpdateParams.changePassword(DerivedKeyUpdateParamsChangePassword data) =
      _ChangePassword;

  factory DerivedKeyUpdateParams.fromJson(Map<String, dynamic> json) =>
      _$DerivedKeyUpdateParamsFromJson(json);
}
