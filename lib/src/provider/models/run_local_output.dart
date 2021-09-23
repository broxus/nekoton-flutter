import 'package:freezed_annotation/freezed_annotation.dart';

part 'run_local_output.freezed.dart';
part 'run_local_output.g.dart';

@freezed
class RunLocalOutput with _$RunLocalOutput {
  @JsonSerializable()
  const factory RunLocalOutput({
    Map<String, dynamic>? output,
    required int code,
  }) = _RunLocalOutput;

  factory RunLocalOutput.fromJson(Map<String, dynamic> json) => _$RunLocalOutputFromJson(json);
}
