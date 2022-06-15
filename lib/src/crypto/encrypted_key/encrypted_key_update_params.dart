import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/update_key_input.dart';
import 'encrypted_key_update_params_change_password.dart';
import 'encrypted_key_update_params_rename.dart';

part 'encrypted_key_update_params.freezed.dart';
part 'encrypted_key_update_params.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class EncryptedKeyUpdateParams with _$EncryptedKeyUpdateParams implements UpdateKeyInput {
  const factory EncryptedKeyUpdateParams.rename(EncryptedKeyUpdateParamsRename data) = _EncryptedKeyUpdateParamsRename;

  const factory EncryptedKeyUpdateParams.changePassword(EncryptedKeyUpdateParamsChangePassword data) =
      _EncryptedKeyUpdateParamsChangePassword;

  factory EncryptedKeyUpdateParams.fromJson(Map<String, dynamic> json) => _$EncryptedKeyUpdateParamsFromJson(json);
}
