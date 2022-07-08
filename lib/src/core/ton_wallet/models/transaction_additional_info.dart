import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/de_pool_on_round_complete_notification.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/de_pool_receive_answer_notification.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/token_wallet_deployed_notification.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/wallet_interaction_info.dart';

part 'transaction_additional_info.freezed.dart';
part 'transaction_additional_info.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class TransactionAdditionalInfo with _$TransactionAdditionalInfo {
  const factory TransactionAdditionalInfo.comment(String data) = _TransactionAdditionalInfoComment;

  const factory TransactionAdditionalInfo.dePoolOnRoundComplete(
    DePoolOnRoundCompleteNotification data,
  ) = _TransactionAdditionalInfoDePoolOnRoundComplete;

  const factory TransactionAdditionalInfo.dePoolReceiveAnswer(
    DePoolReceiveAnswerNotification data,
  ) = _TransactionAdditionalInfoDePoolReceiveAnswer;

  const factory TransactionAdditionalInfo.tokenWalletDeployed(
    TokenWalletDeployedNotification data,
  ) = _TransactionAdditionalInfoTokenWalletDeployed;

  const factory TransactionAdditionalInfo.walletInteraction(WalletInteractionInfo data) =
      _TransactionAdditionalInfoWalletInteraction;

  factory TransactionAdditionalInfo.fromJson(Map<String, dynamic> json) =>
      _$TransactionAdditionalInfoFromJson(json);
}
