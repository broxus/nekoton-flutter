import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_wallet_version.g.dart';

@HiveType(typeId: 218)
enum TokenWalletVersion {
  @HiveField(0)
  @JsonValue('Tip3v1')
  tip3v1,
  @HiveField(1)
  @JsonValue('Tip3v2')
  tip3v2,
  @HiveField(2)
  @JsonValue('Tip3v3')
  tip3v3,
  @HiveField(3)
  @JsonValue('Tip3v4')
  tip3v4,
}
