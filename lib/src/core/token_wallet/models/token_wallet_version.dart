import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_wallet_version.g.dart';

@HiveType(typeId: 218)
@JsonEnum(
  alwaysCreate: true,
  fieldRename: FieldRename.pascal,
)
enum TokenWalletVersion {
  @HiveField(0)
  oldTip3v4,
  @HiveField(1)
  tip3,
}

TokenWalletVersion tokenWalletVersionFromEnumString(String string) =>
    _$TokenWalletVersionEnumMap.entries.firstWhere((e) => e.value == string).key;
