import 'package:freezed_annotation/freezed_annotation.dart';

import 'tokens_object.dart';

part 'decode_input_output.freezed.dart';
part 'decode_input_output.g.dart';

@freezed
class DecodeInputOutput with _$DecodeInputOutput {
  @JsonSerializable()
  const factory DecodeInputOutput({
    required String method,
    required TokensObject input,
  }) = _DecodeInputOutput;

  factory DecodeInputOutput.fromJson(Map<String, dynamic> json) => _$DecodeInputOutputFromJson(json);
}
