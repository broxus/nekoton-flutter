import 'package:hive/hive.dart';

part 'eth_event_status.g.dart';

@HiveType(typeId: 28)
enum EthEventStatus {
  @HiveField(0)
  inProcess,
  @HiveField(1)
  confirmed,
  @HiveField(2)
  executed,
  @HiveField(3)
  rejected,
}
