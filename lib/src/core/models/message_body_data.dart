import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_body_data.freezed.dart';
part 'message_body_data.g.dart';

@freezed
class MessageBodyData with _$MessageBodyData {
  @JsonSerializable()
  const factory MessageBodyData.comment({
    required String value,
  }) = _MessageComment;

  @JsonSerializable()
  const factory MessageBodyData.onRoundComplete({
    required String roundId,
    required String reward,
    required String ordinaryStake,
    required String vestingStake,
    required String lockStake,
    required String reinvest,
    required String reason,
  }) = _OnRoundComplete;

  @JsonSerializable()
  const factory MessageBodyData.receiveAnswer({
    required String errcode,
    required String comment,
  }) = _ReceiveAnswer;

  @JsonSerializable()
  const factory MessageBodyData.onTransfer({
    required String source,
    required String amount,
  }) = _OnTransfer;

  @JsonSerializable()
  const factory MessageBodyData.withdrawFromPoolingRound({
    required String withdrawValue,
  }) = _WithdrawFromPoolingRound;

  @JsonSerializable()
  const factory MessageBodyData.withdrawPart({
    required String withdrawValue,
  }) = _WithdrawPart;

  @JsonSerializable()
  const factory MessageBodyData.withdrawAll() = _WithdrawAll;

  @JsonSerializable()
  const factory MessageBodyData.cancelWithdrawal() = _CancelWithdrawal;

  @JsonSerializable()
  const factory MessageBodyData.addOrdinaryStake({
    required String stake,
  }) = _AddOrdinaryStake;

  @JsonSerializable()
  const factory MessageBodyData.setVestingDonor({
    required String donor,
  }) = _SetVestingDonor;

  @JsonSerializable()
  const factory MessageBodyData.setLockDonor({
    required String donor,
  }) = _SetLockDonor;

  @JsonSerializable()
  const factory MessageBodyData.addVestingStake({
    required String stake,
    required String beneficiary,
    required String withdrawalPeriod,
    required String totalPeriod,
  }) = _AddVestingStake;

  @JsonSerializable()
  const factory MessageBodyData.addLockStake({
    required String stake,
    required String beneficiary,
    required String withdrawalPeriod,
    required String totalPeriod,
  }) = _AddLockStake;

  @JsonSerializable()
  const factory MessageBodyData.transferStake({
    required String dest,
    required String amount,
  }) = _TransferStake;

  @JsonSerializable()
  const factory MessageBodyData.receiveFunds() = _ReceiveFunds;

  factory MessageBodyData.fromJson(Map<String, dynamic> json) => _$MessageBodyDataFromJson(json);
}
