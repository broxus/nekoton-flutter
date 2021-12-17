import 'package:freezed_annotation/freezed_annotation.dart';

part 'participant_stake.freezed.dart';
part 'participant_stake.g.dart';

@freezed
class ParticipantStake with _$ParticipantStake {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ParticipantStake({
    required int remainingAmount,
    required int lastWithdrawalTime,
    required int withdrawalPeriod,
    required int withdrawalValue,
    required String owner,
  }) = _ParticipantStake;

  factory ParticipantStake.fromJson(Map<String, dynamic> json) => _$ParticipantStakeFromJson(json);
}
