import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/de_pool_on_round_complete_notification.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/de_pool_receive_answer_notification.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/token_wallet_deployed_notification.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/wallet_interaction_info.dart';

part 'transaction_additional_info.freezed.dart';
part 'transaction_additional_info.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class TransactionAdditionalInfo with _$TransactionAdditionalInfo {
  const factory TransactionAdditionalInfo.comment(String data) = _Comment;

  const factory TransactionAdditionalInfo.dePoolOnRoundComplete(
    DePoolOnRoundCompleteNotification data,
  ) = _DePoolOnRoundComplete;

  const factory TransactionAdditionalInfo.dePoolReceiveAnswer(
    DePoolReceiveAnswerNotification data,
  ) = _DePoolReceiveAnswer;

  const factory TransactionAdditionalInfo.tokenWalletDeployed(
    TokenWalletDeployedNotification data,
  ) = _TokenWalletDeployed;

  const factory TransactionAdditionalInfo.walletInteraction(WalletInteractionInfo data) =
      _WalletInteraction;

  factory TransactionAdditionalInfo.fromJson(Map<String, dynamic> json) =>
      _$TransactionAdditionalInfoFromJson(json);
}
