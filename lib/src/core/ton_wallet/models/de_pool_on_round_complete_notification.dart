import 'package:freezed_annotation/freezed_annotation.dart';

part 'de_pool_on_round_complete_notification.freezed.dart';
part 'de_pool_on_round_complete_notification.g.dart';

@freezed
class DePoolOnRoundCompleteNotification with _$DePoolOnRoundCompleteNotification {
  const factory DePoolOnRoundCompleteNotification({
    required String roundId,
    required String reward,
    required String ordinaryStake,
    required String vestingStake,
    required String lockStake,
    required bool reinvest,
    required int reason,
  }) = _DePoolOnRoundCompleteNotification;

  factory DePoolOnRoundCompleteNotification.fromJson(Map<String, dynamic> json) =>
      _$DePoolOnRoundCompleteNotificationFromJson(json);
}
