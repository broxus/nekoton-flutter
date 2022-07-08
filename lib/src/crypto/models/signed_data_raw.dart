import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/models/signature_parts.dart';

part 'signed_data_raw.freezed.dart';
part 'signed_data_raw.g.dart';

@freezed
class SignedDataRaw with _$SignedDataRaw {
  const factory SignedDataRaw({
    required String signature,
    required String signatureHex,
    required SignatureParts signatureParts,
  }) = _SignedDataRaw;

  factory SignedDataRaw.fromJson(Map<String, dynamic> json) => _$SignedDataRawFromJson(json);
}
