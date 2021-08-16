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

  @JsonSerializable()
  const factory WalletType.walletV3() = _WalletV3;

  factory WalletType.fromJson(Map<String, dynamic> json) => _$WalletTypeFromJson(json);
}

extension ToInt on WalletType {
  int toInt() => when(
        multisig: (multisigType) {
          switch (multisigType) {
            case MultisigType.safeMultisigWallet:
              return 4;
            case MultisigType.safeMultisigWallet24h:
              return 3;
            case MultisigType.setcodeMultisigWallet:
              return 2;
            case MultisigType.surfWallet:
              return 1;
          }
        },
        walletV3: () => 0,
      );
}
