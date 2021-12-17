import 'package:freezed_annotation/freezed_annotation.dart';

import '../../accounts_storage/models/wallet_type.dart';
import '../../models/contract_state.dart';

part 'existing_wallet_info.freezed.dart';
part 'existing_wallet_info.g.dart';

@freezed
class ExistingWalletInfo with _$ExistingWalletInfo {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory ExistingWalletInfo({
    required String address,
    required String publicKey,
    required WalletType walletType,
    required ContractState contractState,
  }) = _ExistingWalletInfo;

  factory ExistingWalletInfo.fromJson(Map<String, dynamic> json) => _$ExistingWalletInfoFromJson(json);
}
