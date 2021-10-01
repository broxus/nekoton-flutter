import 'package:json_annotation/json_annotation.dart';

enum WalletContractType {
  @JsonValue('SafeMultisigWallet')
  safeMultisigWallet,
  @JsonValue('SafeMultisigWallet24h')
  safeMultisigWallet24h,
  @JsonValue('SetcodeMultisigWallet')
  setcodeMultisigWallet,
  @JsonValue('BridgeMultisigWallet')
  bridgeMultisigWallet,
  @JsonValue('SurfWallet')
  surfWallet,
  @JsonValue('WalletV3')
  walletV3,
}
