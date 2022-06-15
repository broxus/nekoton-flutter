import 'package:json_annotation/json_annotation.dart';

part 'token_wallet_version.g.dart';

@JsonEnum(
  alwaysCreate: true,
  fieldRename: FieldRename.pascal,
)
enum TokenWalletVersion {
  oldTip3v4,
  tip3;

  @override
  String toString() => _$TokenWalletVersionEnumMap[this]!;
}
