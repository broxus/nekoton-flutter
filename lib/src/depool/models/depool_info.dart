import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'depool_info.freezed.dart';
part 'depool_info.g.dart';

@freezed
class DePoolInfo with _$DePoolInfo {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DePoolInfo({
    required bool poolClosed,
    required int minStake,
    required int validatorAssurance,
    required int participantRewardFraction,
    required int validatorRewardFraction,
    required int balanceThreshold,
    required String validatorWallet,
    required List<String> proxies,
    required int stakeFee,
    required int retOrReinvFee,
    required int proxyFee,
  }) = _DePoolInfo;

  factory DePoolInfo.fromJson(Map<String, dynamic> json) => _$DePoolInfoFromJson(json);
}
