import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_wallet_version.g.dart';

@HiveType(typeId: 218)
enum TokenWalletVersion {
  @HiveField(0)
  @JsonValue('OldTip3v4')
  oldTip3v4,
  @HiveField(1)
  @JsonValue('Tip3')
  tip3,
}
