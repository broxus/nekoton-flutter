import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/token_incoming_transfer.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/token_outgoing_transfer.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/token_swap_back.dart';

part 'token_wallet_transaction.freezed.dart';
part 'token_wallet_transaction.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class TokenWalletTransaction with _$TokenWalletTransaction {
  const factory TokenWalletTransaction.incomingTransfer(TokenIncomingTransfer data) =
      _IncomingTransfer;

  const factory TokenWalletTransaction.outgoingTransfer(TokenOutgoingTransfer data) =
      _OutgoingTransfer;

  const factory TokenWalletTransaction.swapBack(TokenSwapBack data) = _SwapBack;

  const factory TokenWalletTransaction.accept(String data) = _Accept;

  const factory TokenWalletTransaction.transferBounced(String data) = _TransferBounced;

  const factory TokenWalletTransaction.swapBackBounced(String data) = _SwapBackBounced;

  factory TokenWalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$TokenWalletTransactionFromJson(json);
}
