import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'token_wallet_details.freezed.dart';
part 'token_wallet_details.g.dart';

@freezed
class TokenWalletDetails with _$TokenWalletDetails {
  @HiveType(typeId: 209)
  const factory TokenWalletDetails({
    @HiveField(0) required String rootAddress,
    @HiveField(1) required String ownerAddress,
    @HiveField(2) required String balance,
  }) = _TokenWalletDetails;

  factory TokenWalletDetails.fromJson(Map<String, dynamic> json) =>
      _$TokenWalletDetailsFromJson(json);
}
