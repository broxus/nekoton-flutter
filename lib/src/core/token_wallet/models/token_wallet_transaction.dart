import 'package:freezed_annotation/freezed_annotation.dart';

import 'token_incoming_transfer.dart';
import 'token_outgoing_transfer.dart';
import 'token_swap_back.dart';

part 'token_wallet_transaction.freezed.dart';
part 'token_wallet_transaction.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class TokenWalletTransaction with _$TokenWalletTransaction {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TokenWalletTransaction.incomingTransfer({
    required TokenIncomingTransfer tokenIncomingTransfer,
  }) = _IncomingTransfer;

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TokenWalletTransaction.outgoingTransfer({
    required TokenOutgoingTransfer tokenOutgoingTransfer,
  }) = _OutgoingTransfer;

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TokenWalletTransaction.swapBack({
    required TokenSwapBack tokenSwapBack,
  }) = _SwapBack;

  @JsonSerializable()
  const factory TokenWalletTransaction.accept({
    required String value,
  }) = _Accept;

  @JsonSerializable()
  const factory TokenWalletTransaction.transferBounced({
    required String value,
  }) = _TransferBounced;

  @JsonSerializable()
  const factory TokenWalletTransaction.swapBackBounced({
    required String value,
  }) = _SwapBackBounced;

  factory TokenWalletTransaction.fromJson(Map<String, dynamic> json) => _$TokenWalletTransactionFromJson(json);
}
