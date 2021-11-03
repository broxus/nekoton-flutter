import 'package:freezed_annotation/freezed_annotation.dart';

import 'multisig_type.dart';

part 'wallet_type.freezed.dart';
part 'wallet_type.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class WalletType with _$WalletType {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WalletType.multisig({
    required MultisigType multisigType,
  }) = _Multisig;

  const factory WalletType.walletV3() = _WalletV3;

  factory WalletType.fromJson(Map<String, dynamic> json) => _$WalletTypeFromJson(json);
}

extension ToInt on WalletType {
  int toInt() => when(
        multisig: (multisigType) {
          switch (multisigType) {
            case MultisigType.safeMultisigWallet:
              return 1;
            case MultisigType.safeMultisigWallet24h:
              return 2;
            case MultisigType.setcodeMultisigWallet:
              return 3;
            case MultisigType.bridgeMultisigWallet:
              return 4;
            case MultisigType.surfWallet:
              return 5;
          }
        },
        walletV3: () => 6,
      );
}

extension Describe on WalletType {
  String describe() => when(
        multisig: (multisigType) {
          switch (multisigType) {
            case MultisigType.safeMultisigWallet:
              return 'SafeMultisig';
            case MultisigType.safeMultisigWallet24h:
              return 'SafeMultisig24';
            case MultisigType.setcodeMultisigWallet:
              return 'SetcodeMultisig';
            case MultisigType.bridgeMultisigWallet:
              return 'BridgeMultisig';
            case MultisigType.surfWallet:
              return 'Surf';
          }
        },
        walletV3: () => 'WalletV3',
      );
}
