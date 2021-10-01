import 'package:freezed_annotation/freezed_annotation.dart';

import 'tokens_object.dart';

part 'decode_output_output.freezed.dart';
part 'decode_output_output.g.dart';

@freezed
class DecodeOutputOutput with _$DecodeOutputOutput {
  @JsonSerializable()
  const factory DecodeOutputOutput({
    required String method,
    required TokensObject output,
  }) = _DecodeOutputOutput;

  factory DecodeOutputOutput.fromJson(Map<String, dynamic> json) => _$DecodeOutputOutputFromJson(json);
}
