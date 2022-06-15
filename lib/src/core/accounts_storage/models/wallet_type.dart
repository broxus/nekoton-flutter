import 'package:freezed_annotation/freezed_annotation.dart';

import 'multisig_type.dart';

part 'wallet_type.freezed.dart';
part 'wallet_type.g.dart';

@Freezed(unionKey: 'type')
class WalletType with _$WalletType {
  const factory WalletType.multisig(MultisigType data) = _WalletTypeMultisig;

  const factory WalletType.walletV3() = _WalletTypeWalletV3;

  const factory WalletType.highloadWalletV2() = _WalletTypeHighloadWalletV2;

  factory WalletType.fromJson(Map<String, dynamic> json) => _$WalletTypeFromJson(json);
}
