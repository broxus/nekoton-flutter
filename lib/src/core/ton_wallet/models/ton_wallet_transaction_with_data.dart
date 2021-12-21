import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

import '../../models/transaction.dart';
import 'transaction_additional_info.dart';

part 'ton_wallet_transaction_with_data.freezed.dart';
part 'ton_wallet_transaction_with_data.g.dart';

@freezed
class TonWalletTransactionWithData with _$TonWalletTransactionWithData {
  @HiveType(typeId: 40)
  const factory TonWalletTransactionWithData({
    @HiveField(0) required Transaction transaction,
    @HiveField(1) TransactionAdditionalInfo? data,
  }) = _TonWalletTransactionWithData;

  factory TonWalletTransactionWithData.fromJson(Map<String, dynamic> json) =>
      _$TonWalletTransactionWithDataFromJson(json);
}
