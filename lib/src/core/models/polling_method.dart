import 'package:json_annotation/json_annotation.dart';

part 'polling_method.g.dart';

@JsonEnum(alwaysCreate: true)
enum PollingMethod {
  manual,
  reliable,
}

PollingMethod pollingMethodFromEnumString(String string) =>
    _$PollingMethodEnumMap.entries.firstWhere((e) => e.value == string).key;
