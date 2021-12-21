import 'package:hive_flutter/hive_flutter.dart';

part 'account_status.g.dart';

@HiveType(typeId: 10)
enum AccountStatus {
  @HiveField(0)
  uninit,
  @HiveField(1)
  frozen,
  @HiveField(2)
  active,
  @HiveField(3)
  nonexist,
}
