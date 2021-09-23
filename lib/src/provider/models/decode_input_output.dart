import 'package:freezed_annotation/freezed_annotation.dart';

part 'decode_input_output.freezed.dart';
part 'decode_input_output.g.dart';

@freezed
class DecodeInputOutput with _$DecodeInputOutput {
  @JsonSerializable()
  const factory DecodeInputOutput({
    required String method,
    required Map<String, dynamic> input,
  }) = _DecodeInputOutput;

  factory DecodeInputOutput.fromJson(Map<String, dynamic> json) => _$DecodeInputOutputFromJson(json);
}
