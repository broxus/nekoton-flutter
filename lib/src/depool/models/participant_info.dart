import 'package:freezed_annotation/freezed_annotation.dart';

import 'participant_stake.dart';

part 'participant_info.freezed.dart';
part 'participant_info.g.dart';

@freezed
class ParticipantInfo with _$ParticipantInfo {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory ParticipantInfo({
    required int total,
    required int withdrawValue,
    required bool reinvest,
    required int reward,
    required Map<int, int> stakes,
    required Map<int, ParticipantStake> vestings,
    required Map<int, ParticipantStake> locks,
    required String vestingDonor,
    required String lockDonor,
  }) = _ParticipantInfo;

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) => _$ParticipantInfoFromJson(json);
}
