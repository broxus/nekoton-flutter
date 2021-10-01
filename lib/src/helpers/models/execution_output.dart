import 'package:freezed_annotation/freezed_annotation.dart';

part 'execution_output.freezed.dart';
part 'execution_output.g.dart';

@freezed
class ExecutionOutput with _$ExecutionOutput {
  @JsonSerializable()
  const factory ExecutionOutput({
    required dynamic output,
    required int code,
  }) = _ExecutionOutput;

  factory ExecutionOutput.fromJson(Map<String, dynamic> json) => _$ExecutionOutputFromJson(json);
}
