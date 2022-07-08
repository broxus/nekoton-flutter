import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/models/signature_parts.dart';

part 'signed_data.freezed.dart';
part 'signed_data.g.dart';

@freezed
class SignedData with _$SignedData {
  const factory SignedData({
    required String dataHash,
    required String signature,
    required String signatureHex,
    required SignatureParts signatureParts,
  }) = _SignedData;

  factory SignedData.fromJson(Map<String, dynamic> json) => _$SignedDataFromJson(json);
}
