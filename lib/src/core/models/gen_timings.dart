import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gen_timings.freezed.dart';
part 'gen_timings.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class GenTimings with _$GenTimings {
  @JsonSerializable()
  const factory GenTimings.unknown() = _Unknown;

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory GenTimings.known({
    required String genLt,
    required int genUtime,
  }) = _Known;

  factory GenTimings.fromJson(Map<String, dynamic> json) => _$GenTimingsFromJson(json);
}
