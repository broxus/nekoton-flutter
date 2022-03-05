import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'multisig_type.g.dart';

@HiveType(typeId: 211)
enum MultisigType {
  @HiveField(0)
  @JsonValue('SafeMultisigWallet')
  safeMultisigWallet,
  @HiveField(1)
  @JsonValue('SafeMultisigWallet24h')
  safeMultisigWallet24h,
  @HiveField(2)
  @JsonValue('SetcodeMultisigWallet')
  setcodeMultisigWallet,
  @HiveField(3)
  @JsonValue('SetcodeMultisigWallet24h')
  setcodeMultisigWallet24h,
  @HiveField(4)
  @JsonValue('BridgeMultisigWallet')
  bridgeMultisigWallet,
  @HiveField(5)
  @JsonValue('SurfWallet')
  surfWallet,
}
