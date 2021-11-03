import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../models/transaction.dart';
import 'transaction_additional_info.dart';

part 'ton_wallet_transaction_with_data.freezed.dart';
part 'ton_wallet_transaction_with_data.g.dart';

@freezed
class TonWalletTransactionWithData with _$TonWalletTransactionWithData {
  const factory TonWalletTransactionWithData({
    required Transaction transaction,
    TransactionAdditionalInfo? data,
  }) = _TonWalletTransactionWithData;

  factory TonWalletTransactionWithData.fromJson(Map<String, dynamic> json) =>
      _$TonWalletTransactionWithDataFromJson(json);
}
