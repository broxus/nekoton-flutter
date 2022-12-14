import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'multisig_type.g.dart';

@HiveType(typeId: 211)
@JsonEnum(fieldRename: FieldRename.pascal)
enum MultisigType {
  @HiveField(0)
  safeMultisigWallet,
  @HiveField(1)
  safeMultisigWallet24h,
  @HiveField(2)
  setcodeMultisigWallet,
  @HiveField(3)
  setcodeMultisigWallet24h,
  @HiveField(4)
  bridgeMultisigWallet,
  @HiveField(5)
  surfWallet,
  @HiveField(6)
  multisig2,
  multisig2_1,
}
