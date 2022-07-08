import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/tokens_object.dart';

part 'execution_output.freezed.dart';
part 'execution_output.g.dart';

@freezed
class ExecutionOutput with _$ExecutionOutput {
  const factory ExecutionOutput({
    @JsonKey(includeIfNull: false) TokensObject? output,
    required int code,
  }) = _ExecutionOutput;

  factory ExecutionOutput.fromJson(Map<String, dynamic> json) => _$ExecutionOutputFromJson(json);
}
