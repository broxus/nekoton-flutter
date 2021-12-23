import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'eth_event_status.g.dart';

@HiveType(typeId: 28)
enum EthEventStatus {
  @HiveField(0)
  @JsonValue('InProcess')
  inProcess,
  @HiveField(1)
  @JsonValue('Confirmed')
  confirmed,
  @HiveField(2)
  @JsonValue('Executed')
  executed,
  @HiveField(3)
  @JsonValue('Rejected')
  rejected,
}
