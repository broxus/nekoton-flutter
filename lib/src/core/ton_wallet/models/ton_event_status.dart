import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ton_event_status.g.dart';

@HiveType(typeId: 39)
enum TonEventStatus {
  @HiveField(0)
  @JsonValue('InProcess')
  inProcess,
  @HiveField(1)
  @JsonValue('Confirmed')
  confirmed,
  @HiveField(2)
  @JsonValue('Rejected')
  rejected,
}
