import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/encrypted_data.dart';

part 'encrypt_data_output.freezed.dart';
part 'encrypt_data_output.g.dart';

@freezed
class EncryptDataOutput with _$EncryptDataOutput {
  @JsonSerializable(explicitToJson: true)
  const factory EncryptDataOutput({
    required List<EncryptedData> encryptedData,
  }) = _EncryptDataOutput;

  factory EncryptDataOutput.fromJson(Map<String, dynamic> json) => _$EncryptDataOutputFromJson(json);
}
