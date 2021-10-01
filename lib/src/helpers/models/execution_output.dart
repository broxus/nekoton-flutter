import 'package:freezed_annotation/freezed_annotation.dart';

import '../../provider/models/tokens_object.dart';

part 'execution_output.freezed.dart';
part 'execution_output.g.dart';

@freezed
class ExecutionOutput with _$ExecutionOutput {
  @JsonSerializable()
  const factory ExecutionOutput({
    required TokensObject output,
    required int code,
  }) = _ExecutionOutput;

  factory ExecutionOutput.fromJson(Map<String, dynamic> json) => _$ExecutionOutputFromJson(json);
}
