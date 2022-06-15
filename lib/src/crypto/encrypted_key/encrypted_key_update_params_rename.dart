import 'package:freezed_annotation/freezed_annotation.dart';

part 'encrypted_key_update_params_rename.freezed.dart';
part 'encrypted_key_update_params_rename.g.dart';

@freezed
class EncryptedKeyUpdateParamsRename with _$EncryptedKeyUpdateParamsRename {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory EncryptedKeyUpdateParamsRename({
    required String publicKey,
    required String name,
  }) = _EncryptedKeyUpdateParamsRenameRename;

  factory EncryptedKeyUpdateParamsRename.fromJson(Map<String, dynamic> json) =>
      _$EncryptedKeyUpdateParamsRenameFromJson(json);
}
