import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/models/transactions_batch_info.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/token_wallet_transaction_with_data.dart';

part 'on_token_wallet_transactions_found_payload.freezed.dart';
part 'on_token_wallet_transactions_found_payload.g.dart';

@freezed
class OnTokenWalletTransactionsFoundPayload with _$OnTokenWalletTransactionsFoundPayload {
  const factory OnTokenWalletTransactionsFoundPayload({
    required List<TokenWalletTransactionWithData> transactions,
    required TransactionsBatchInfo batchInfo,
  }) = _OnTokenWalletTransactionsFoundPayload;

  factory OnTokenWalletTransactionsFoundPayload.fromJson(Map<String, dynamic> json) =>
      _$OnTokenWalletTransactionsFoundPayloadFromJson(json);
}
