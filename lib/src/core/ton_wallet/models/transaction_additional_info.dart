import 'package:freezed_annotation/freezed_annotation.dart';

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
  const factory TransactionAdditionalInfo.comment({
    required String value,
  }) = _Comment;

  const factory TransactionAdditionalInfo.dePoolOnRoundComplete({
    required DePoolOnRoundCompleteNotification notification,
  }) = _DePoolOnRoundComplete;

  const factory TransactionAdditionalInfo.dePoolReceiveAnswer({
    required DePoolReceiveAnswerNotification notification,
  }) = _DePoolReceiveAnswer;

  const factory TransactionAdditionalInfo.tokenWalletDeployed({
    required TokenWalletDeployedNotification notification,
  }) = _TokenWalletDeployed;

  const factory TransactionAdditionalInfo.ethEventStatusChanged({
    required EthEventStatus status,
  }) = _EthEventStatusChanged;

  const factory TransactionAdditionalInfo.tonEventStatusChanged({
    required TonEventStatus status,
  }) = _TonEventStatusChanged;

  const factory TransactionAdditionalInfo.walletInteraction({
    required WalletInteractionInfo info,
  }) = _WalletInteraction;

  factory TransactionAdditionalInfo.fromJson(Map<String, dynamic> json) => _$TransactionAdditionalInfoFromJson(json);
}
