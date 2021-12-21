import 'package:hive/hive.dart';

part 'ton_event_status.g.dart';

@HiveType(typeId: 39)
enum TonEventStatus {
  @HiveField(0)
  inProcess,
  @HiveField(1)
  confirmed,
  @HiveField(2)
  rejected,
}
