import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/token_wallet_version.dart';

part 'root_token_contract_details.freezed.dart';
part 'root_token_contract_details.g.dart';

@freezed
class RootTokenContractDetails with _$RootTokenContractDetails {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory RootTokenContractDetails({
    required TokenWalletVersion version,
    required String name,
    required String symbol,
    required int decimals,
    required String ownerAddress,
    required String totalSupply,
  }) = _RootTokenContractDetails;

  factory RootTokenContractDetails.fromJson(Map<String, dynamic> json) =>
      _$RootTokenContractDetailsFromJson(json);
}
