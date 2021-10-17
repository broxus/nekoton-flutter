import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../core/accounts_storage/models/multisig_type.dart';
import '../../core/accounts_storage/models/wallet_type.dart';

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
  @JsonValue('BridgeMultisigWallet')
  bridgeMultisigWallet,
  @HiveField(4)
  @JsonValue('SurfWallet')
  surfWallet,
  @HiveField(5)
  @JsonValue('WalletV3')
  walletV3,
}

extension WalletTypeX on WalletType {
  WalletContractType toWalletType() => when(
        multisig: (multisigType) {
          switch (multisigType) {
            case MultisigType.safeMultisigWallet:
              return WalletContractType.safeMultisigWallet;
            case MultisigType.safeMultisigWallet24h:
              return WalletContractType.safeMultisigWallet24h;
            case MultisigType.setcodeMultisigWallet:
              return WalletContractType.setcodeMultisigWallet;
            case MultisigType.bridgeMultisigWallet:
              return WalletContractType.bridgeMultisigWallet;
            case MultisigType.surfWallet:
              return WalletContractType.surfWallet;
          }
        },
        walletV3: () => WalletContractType.walletV3,
      );
}
