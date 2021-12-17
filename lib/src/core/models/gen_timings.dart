import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'gen_timings.freezed.dart';
part 'gen_timings.g.dart';

@freezed
class GenTimings with _$GenTimings {
  @HiveType(typeId: 216)
  const factory GenTimings({
    @HiveField(0) required String genLt,
    @HiveField(1) required int genUtime,
  }) = _GenTimings;

  factory GenTimings.fromJson(Map<String, dynamic> json) => _$GenTimingsFromJson(json);
}
