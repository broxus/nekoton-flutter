import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'de_pool_on_round_complete_notification.freezed.dart';
part 'de_pool_on_round_complete_notification.g.dart';

@freezed
class DePoolOnRoundCompleteNotification with _$DePoolOnRoundCompleteNotification {
  @HiveType(typeId: 26)
  const factory DePoolOnRoundCompleteNotification({
    @HiveField(0) required String roundId,
    @HiveField(1) required String reward,
    @HiveField(2) required String ordinaryStake,
    @HiveField(3) required String vestingStake,
    @HiveField(4) required String lockStake,
    @HiveField(5) required bool reinvest,
    @HiveField(6) required int reason,
  }) = _DePoolOnRoundCompleteNotification;

  factory DePoolOnRoundCompleteNotification.fromJson(Map<String, dynamic> json) =>
      _$DePoolOnRoundCompleteNotificationFromJson(json);
}
