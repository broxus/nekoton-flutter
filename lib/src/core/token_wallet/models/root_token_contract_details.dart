import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'token_wallet_version.dart';

part 'root_token_contract_details.freezed.dart';
part 'root_token_contract_details.g.dart';

@freezed
class RootTokenContractDetails with _$RootTokenContractDetails {
  @JsonSerializable(fieldRename: FieldRename.snake)
  @HiveType(typeId: 210)
  const factory RootTokenContractDetails({
    @HiveField(0) required TokenWalletVersion version,
    @HiveField(1) required String name,
    @HiveField(2) required String symbol,
    @HiveField(3) required int decimals,
    @HiveField(4) required String ownerAddress,
    @HiveField(5) required String totalSupply,
  }) = _RootTokenContractDetails;

  factory RootTokenContractDetails.fromJson(Map<String, dynamic> json) =>
      _$RootTokenContractDetailsFromJson(json);
}
