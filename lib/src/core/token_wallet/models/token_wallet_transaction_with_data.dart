import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/transaction.dart';
import 'token_wallet_transaction.dart';

part 'token_wallet_transaction_with_data.freezed.dart';
part 'token_wallet_transaction_with_data.g.dart';

@freezed
class TokenWalletTransactionWithData
    with _$TokenWalletTransactionWithData
    implements Comparable<TokenWalletTransactionWithData> {
  @HiveType(typeId: 21)
  const factory TokenWalletTransactionWithData({
    @HiveField(0) required Transaction transaction,
    @HiveField(1) TokenWalletTransaction? data,
  }) = _TokenWalletTransactionWithData;

  factory TokenWalletTransactionWithData.fromJson(Map<String, dynamic> json) =>
      _$TokenWalletTransactionWithDataFromJson(json);

  const TokenWalletTransactionWithData._();

  @override
  int compareTo(TokenWalletTransactionWithData other) => -transaction.createdAt.compareTo(other.transaction.createdAt);
}
