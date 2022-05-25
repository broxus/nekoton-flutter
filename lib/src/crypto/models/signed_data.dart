import 'package:freezed_annotation/freezed_annotation.dart';

import 'signature_parts.dart';

part 'signed_data.freezed.dart';
part 'signed_data.g.dart';

@freezed
class SignedData with _$SignedData {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory SignedData({
    required String dataHash,
    required String signature,
    required String signatureHex,
    required SignatureParts signatureParts,
  }) = _SignedData;

  factory SignedData.fromJson(Map<String, dynamic> json) => _$SignedDataFromJson(json);
}
