import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:nekoton_flutter/src/core/models/transaction.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/transaction_additional_info.dart';

part 'ton_wallet_transaction_with_data.freezed.dart';
part 'ton_wallet_transaction_with_data.g.dart';

@freezed
class TonWalletTransactionWithData
    with _$TonWalletTransactionWithData
    implements Comparable<TonWalletTransactionWithData> {
  const factory TonWalletTransactionWithData({
    required Transaction transaction,
    TransactionAdditionalInfo? data,
  }) = _TonWalletTransactionWithData;

  factory TonWalletTransactionWithData.fromJson(Map<String, dynamic> json) =>
      _$TonWalletTransactionWithDataFromJson(json);

  const TonWalletTransactionWithData._();

  @override
  int compareTo(TonWalletTransactionWithData other) =>
      -transaction.createdAt.compareTo(other.transaction.createdAt);
}
