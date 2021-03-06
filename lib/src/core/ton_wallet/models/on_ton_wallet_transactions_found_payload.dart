import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/models/transactions_batch_info.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/ton_wallet_transaction_with_data.dart';

part 'on_ton_wallet_transactions_found_payload.freezed.dart';
part 'on_ton_wallet_transactions_found_payload.g.dart';

@freezed
class OnTonWalletTransactionsFoundPayload with _$OnTonWalletTransactionsFoundPayload {
  const factory OnTonWalletTransactionsFoundPayload({
    required List<TonWalletTransactionWithData> transactions,
    required TransactionsBatchInfo batchInfo,
  }) = _OnTonWalletTransactionsFoundPayload;

  factory OnTonWalletTransactionsFoundPayload.fromJson(Map<String, dynamic> json) =>
      _$OnTonWalletTransactionsFoundPayloadFromJson(json);
}
