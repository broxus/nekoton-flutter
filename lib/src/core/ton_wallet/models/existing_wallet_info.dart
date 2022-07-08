import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/accounts_storage/models/wallet_type.dart';
import 'package:nekoton_flutter/src/core/models/contract_state.dart';

part 'existing_wallet_info.freezed.dart';
part 'existing_wallet_info.g.dart';

@freezed
class ExistingWalletInfo with _$ExistingWalletInfo {
  const factory ExistingWalletInfo({
    required String address,
    required String publicKey,
    required WalletType walletType,
    required ContractState contractState,
  }) = _ExistingWalletInfo;

  factory ExistingWalletInfo.fromJson(Map<String, dynamic> json) =>
      _$ExistingWalletInfoFromJson(json);
}
