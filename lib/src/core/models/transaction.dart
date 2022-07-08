import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/models/account_status.dart';
import 'package:nekoton_flutter/src/core/models/message.dart';
import 'package:nekoton_flutter/src/core/models/transaction_id.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction implements Comparable<Transaction> {
  const factory Transaction({
    required TransactionId id,
    TransactionId? prevTransactionId,
    required int createdAt,
    required bool aborted,
    @JsonKey(includeIfNull: false) int? exitCode,
    @JsonKey(includeIfNull: false) int? resultCode,
    required AccountStatus origStatus,
    required AccountStatus endStatus,
    required String totalFees,
    required Message inMessage,
    required List<Message> outMessages,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

  const Transaction._();

  @override
  int compareTo(Transaction other) => -createdAt.compareTo(other.createdAt);
}
