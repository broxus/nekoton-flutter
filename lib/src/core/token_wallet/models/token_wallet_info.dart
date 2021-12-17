import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/contract_state.dart';
import 'symbol.dart';
import 'token_wallet_version.dart';

part 'token_wallet_info.freezed.dart';
part 'token_wallet_info.g.dart';

@freezed
class TokenWalletInfo with _$TokenWalletInfo {
  const factory TokenWalletInfo({
    required String owner,
    required String address,
    required Symbol symbol,
    required TokenWalletVersion version,
    required String balance,
    required ContractState contractState,
  }) = _TokenWalletInfo;

  factory TokenWalletInfo.fromJson(Map<String, dynamic> json) => _$TokenWalletInfoFromJson(json);
}
