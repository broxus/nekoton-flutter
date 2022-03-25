import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallet_contract_type.g.dart';

@HiveType(typeId: 221)
enum WalletContractType {
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
  @HiveField(6)
  @JsonValue('WalletV3')
  walletV3,
  @HiveField(7)
  @JsonValue('HighloadWalletV2')
  highloadWalletV2,
}
