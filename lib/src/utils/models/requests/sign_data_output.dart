import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/signature_parts.dart';

part 'sign_data_output.freezed.dart';
part 'sign_data_output.g.dart';

@freezed
class SignDataOutput with _$SignDataOutput {
  @JsonSerializable(explicitToJson: true)
  const factory SignDataOutput({
    required String dataHash,
    required String signature,
    required String signatureHex,
    required SignatureParts signatureParts,
  }) = _SignDataOutput;

  factory SignDataOutput.fromJson(Map<String, dynamic> json) => _$SignDataOutputFromJson(json);
}
