import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

import 'token_incoming_transfer.dart';
import 'token_outgoing_transfer.dart';
import 'token_swap_back.dart';

part 'token_wallet_transaction.freezed.dart';
part 'token_wallet_transaction.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class TokenWalletTransaction with _$TokenWalletTransaction {
  @JsonSerializable(fieldRename: FieldRename.snake)
  @HiveType(typeId: 15)
  const factory TokenWalletTransaction.incomingTransfer({
    @HiveField(0) required TokenIncomingTransfer tokenIncomingTransfer,
  }) = _TokenWalletTransactionIncomingTransfer;

  @JsonSerializable(fieldRename: FieldRename.snake)
  @HiveType(typeId: 16)
  const factory TokenWalletTransaction.outgoingTransfer({
    @HiveField(0) required TokenOutgoingTransfer tokenOutgoingTransfer,
  }) = _TokenWalletTransactionOutgoingTransfer;

  @JsonSerializable(fieldRename: FieldRename.snake)
  @HiveType(typeId: 17)
  const factory TokenWalletTransaction.swapBack({
    @HiveField(0) required TokenSwapBack tokenSwapBack,
  }) = _TokenWalletTransactionSwapBack;

  @HiveType(typeId: 18)
  const factory TokenWalletTransaction.accept({
    @HiveField(0) required String value,
  }) = _TokenWalletTransactionAccept;

  @HiveType(typeId: 19)
  const factory TokenWalletTransaction.transferBounced({
    @HiveField(0) required String value,
  }) = _TokenWalletTransactionTransferBounced;

  @HiveType(typeId: 20)
  const factory TokenWalletTransaction.swapBackBounced({
    @HiveField(0) required String value,
  }) = _TokenWalletTransactionSwapBackBounced;

  factory TokenWalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$TokenWalletTransactionFromJson(json);
}
