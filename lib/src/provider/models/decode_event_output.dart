import 'package:freezed_annotation/freezed_annotation.dart';

part 'decode_event_output.freezed.dart';
part 'decode_event_output.g.dart';

@freezed
class DecodeEventOutput with _$DecodeEventOutput {
  @JsonSerializable()
  const factory DecodeEventOutput({
    required String event,
    required Map<String, dynamic> data,
  }) = _DecodeEventOutput;

  factory DecodeEventOutput.fromJson(Map<String, dynamic> json) => _$DecodeEventOutputFromJson(json);
}
