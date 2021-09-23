import 'package:freezed_annotation/freezed_annotation.dart';

import 'account_status.dart';
import 'message.dart';
import 'transaction_id.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  @JsonSerializable(explicitToJson: true)
  const factory Transaction({
    required TransactionId id,
    TransactionId? prevTransactionId,
    required int createdAt,
    required bool aborted,
    required AccountStatus origStatus,
    required AccountStatus endStatus,
    required String totalFees,
    required Message inMessage,
    required List<Message> outMessages,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
}
