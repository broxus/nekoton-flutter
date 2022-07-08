import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/tokens_object.dart';

part 'decoded_input.freezed.dart';
part 'decoded_input.g.dart';

@freezed
class DecodedInput with _$DecodedInput {
  const factory DecodedInput({
    required String method,
    required TokensObject input,
  }) = _DecodedInput;

  factory DecodedInput.fromJson(Map<String, dynamic> json) => _$DecodedInputFromJson(json);
}
