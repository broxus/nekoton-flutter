import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/models/transaction.dart';
import '../../core/models/transaction_id.dart';
import '../../core/models/transactions_batch_info.dart';

part 'transactions_list.freezed.dart';
part 'transactions_list.g.dart';

@freezed
class TransactionsList with _$TransactionsList {
  @JsonSerializable(explicitToJson: true)
  const factory TransactionsList({
    required List<Transaction> transactions,
    TransactionId? continuation,
    TransactionsBatchInfo? info,
  }) = _TransactionsList;

  factory TransactionsList.fromJson(Map<String, dynamic> json) => _$TransactionsListFromJson(json);
}
