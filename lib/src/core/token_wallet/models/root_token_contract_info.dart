import 'package:freezed_annotation/freezed_annotation.dart';
import 'token_wallet_version.dart';

part 'root_token_contract_info.freezed.dart';
part 'root_token_contract_info.g.dart';

@freezed
class RootTokenContractInfo with _$RootTokenContractInfo {
  const factory RootTokenContractInfo({
    required String name,
    required String symbol,
    required int decimals,
    required String address,
    required TokenWalletVersion version,
  }) = _RootTokenContractInfo;

  factory RootTokenContractInfo.fromJson(Map<String, dynamic> json) => _$RootTokenContractInfoFromJson(json);
}
