import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/transaction.dart';
import 'token_wallet_transaction.dart';

part 'token_wallet_transaction_with_data.freezed.dart';
part 'token_wallet_transaction_with_data.g.dart';

@freezed
class TokenWalletTransactionWithData
    with _$TokenWalletTransactionWithData
    implements Comparable<TokenWalletTransactionWithData> {
  const factory TokenWalletTransactionWithData({
    required Transaction transaction,
    TokenWalletTransaction? data,
  }) = _TokenWalletTransactionWithData;

  factory TokenWalletTransactionWithData.fromJson(Map<String, dynamic> json) =>
      _$TokenWalletTransactionWithDataFromJson(json);

  const TokenWalletTransactionWithData._();

  @override
  int compareTo(TokenWalletTransactionWithData other) =>
      -transaction.createdAt.compareTo(other.transaction.createdAt);
}
