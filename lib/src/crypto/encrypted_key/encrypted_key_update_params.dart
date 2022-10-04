import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/encrypted_key/encrypted_key_update_params_change_password.dart';
import 'package:nekoton_flutter/src/crypto/encrypted_key/encrypted_key_update_params_rename.dart';
import 'package:nekoton_flutter/src/crypto/models/update_key_input.dart';

part 'encrypted_key_update_params.freezed.dart';
part 'encrypted_key_update_params.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class EncryptedKeyUpdateParams with _$EncryptedKeyUpdateParams implements UpdateKeyInput {
  const factory EncryptedKeyUpdateParams.rename(EncryptedKeyUpdateParamsRename data) = _Rename;

  const factory EncryptedKeyUpdateParams.changePassword(
    EncryptedKeyUpdateParamsChangePassword data,
  ) = _ChangePassword;

  factory EncryptedKeyUpdateParams.fromJson(Map<String, dynamic> json) =>
      _$EncryptedKeyUpdateParamsFromJson(json);
}
