import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'ton_wallet_details.freezed.dart';
part 'ton_wallet_details.g.dart';

@freezed
class TonWalletDetails with _$TonWalletDetails {
  @JsonSerializable(fieldRename: FieldRename.snake)
  @HiveType(typeId: 212)
  const factory TonWalletDetails({
    @HiveField(0) required bool requiresSeparateDeploy,
    @HiveField(1) required String minAmount,
    @HiveField(2) required bool supportsPayload,
    @HiveField(3) required bool supportsMultipleOwners,
    @HiveField(4) required int expirationTime,
  }) = _TonWalletDetails;

  factory TonWalletDetails.fromJson(Map<String, dynamic> json) => _$TonWalletDetailsFromJson(json);
}
