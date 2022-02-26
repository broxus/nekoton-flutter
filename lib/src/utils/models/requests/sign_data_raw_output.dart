import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/signature_parts.dart';

part 'sign_data_raw_output.freezed.dart';
part 'sign_data_raw_output.g.dart';

@freezed
class SignDataRawOutput with _$SignDataRawOutput {
  @JsonSerializable(explicitToJson: true)
  const factory SignDataRawOutput({
    required String signature,
    required String signatureHex,
    required SignatureParts signatureParts,
  }) = _SignDataRawOutput;

  factory SignDataRawOutput.fromJson(Map<String, dynamic> json) => _$SignDataRawOutputFromJson(json);
}
