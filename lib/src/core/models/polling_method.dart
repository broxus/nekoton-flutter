import 'package:json_annotation/json_annotation.dart';

part 'polling_method.g.dart';

@JsonEnum(alwaysCreate: true)
enum PollingMethod {
  manual,
  reliable;

  @override
  String toString() => _$PollingMethodEnumMap[this]!;
}
