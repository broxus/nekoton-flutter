import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/tokens_object.dart';

part 'run_local_output.freezed.dart';
part 'run_local_output.g.dart';

@freezed
class RunLocalOutput with _$RunLocalOutput {
  @JsonSerializable(includeIfNull: false)
  const factory RunLocalOutput({
    required TokensObject output,
    required int code,
  }) = _RunLocalOutput;

  factory RunLocalOutput.fromJson(Map<String, dynamic> json) => _$RunLocalOutputFromJson(json);
}
