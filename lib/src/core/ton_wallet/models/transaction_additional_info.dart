import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'de_pool_on_round_complete_notification.dart';
import 'de_pool_receive_answer_notification.dart';
import 'eth_event_status.dart';
import 'token_wallet_deployed_notification.dart';
import 'ton_event_status.dart';
import 'wallet_interaction_info.dart';

part 'transaction_additional_info.freezed.dart';
part 'transaction_additional_info.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class TransactionAdditionalInfo with _$TransactionAdditionalInfo {
  @HiveType(typeId: 41)
  const factory TransactionAdditionalInfo.comment({
    @HiveField(0) required String value,
  }) = _TransactionAdditionalInfoComment;

  @HiveType(typeId: 42)
  const factory TransactionAdditionalInfo.dePoolOnRoundComplete({
    @HiveField(0) required DePoolOnRoundCompleteNotification notification,
  }) = _DePoolOnRoundComplete;

  @HiveType(typeId: 43)
  const factory TransactionAdditionalInfo.dePoolReceiveAnswer({
    @HiveField(0) required DePoolReceiveAnswerNotification notification,
  }) = _DePoolReceiveAnswer;

  @HiveType(typeId: 44)
  const factory TransactionAdditionalInfo.tokenWalletDeployed({
    @HiveField(0) required TokenWalletDeployedNotification notification,
  }) = _TokenWalletDeployed;

  @HiveType(typeId: 45)
  const factory TransactionAdditionalInfo.ethEventStatusChanged({
    @HiveField(0) required EthEventStatus status,
  }) = _EthEventStatusChanged;

  @HiveType(typeId: 46)
  const factory TransactionAdditionalInfo.tonEventStatusChanged({
    @HiveField(0) required TonEventStatus status,
  }) = _TonEventStatusChanged;

  @HiveType(typeId: 47)
  const factory TransactionAdditionalInfo.walletInteraction({
    @HiveField(0) required WalletInteractionInfo info,
  }) = _WalletInteraction;

  factory TransactionAdditionalInfo.fromJson(Map<String, dynamic> json) => _$TransactionAdditionalInfoFromJson(json);
}
