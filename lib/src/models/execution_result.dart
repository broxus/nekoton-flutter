import 'package:freezed_annotation/freezed_annotation.dart';

part 'execution_result.freezed.dart';
part 'execution_result.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class ExecutionResult with _$ExecutionResult {
  const factory ExecutionResult.ok(dynamic data) = _ExecutionResultOk;

  const factory ExecutionResult.err(String data) = _ExecutionResultErr;

  const ExecutionResult._();

  dynamic handle() => when(
        ok: (data) => data,
        err: (data) => throw Exception(data),
      );

  factory ExecutionResult.fromJson(Map<String, dynamic> json) => _$ExecutionResultFromJson(json);
}
