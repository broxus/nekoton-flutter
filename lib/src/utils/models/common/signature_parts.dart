import 'package:freezed_annotation/freezed_annotation.dart';

part 'signature_parts.freezed.dart';
part 'signature_parts.g.dart';

@freezed
class SignatureParts with _$SignatureParts {
  const factory SignatureParts({
    required String high,
    required String low,
  }) = _SignatureParts;

  factory SignatureParts.fromJson(Map<String, dynamic> json) => _$SignaturePartsFromJson(json);
}
