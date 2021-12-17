import 'package:hive_flutter/hive_flutter.dart';

part 'token_wallet_version.g.dart';

@HiveType(typeId: 218)
enum TokenWalletVersion {
  @HiveField(0)
  tip3v1,
  @HiveField(1)
  tip3v2,
  @HiveField(2)
  tip3v3,
  @HiveField(3)
  tip3v4,
}
