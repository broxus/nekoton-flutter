import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

import '../../core/models/account_status.dart';
import '../../core/models/transaction_id.dart';
import 'message.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction implements Comparable<Transaction> {
  @JsonSerializable(explicitToJson: true)
  @HiveType(typeId: 22)
  const factory Transaction({
    @HiveField(0) required TransactionId id,
    @HiveField(1) TransactionId? prevTransactionId,
    @HiveField(2) required int createdAt,
    @HiveField(3) required bool aborted,
    @HiveField(4) int? exitCode,
    @HiveField(5) int? resultCode,
    @HiveField(6) required AccountStatus origStatus,
    @HiveField(7) required AccountStatus endStatus,
    @HiveField(8) required String totalFees,
    @HiveField(9) required Message inMessage,
    @HiveField(10) required List<Message> outMessages,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

  const Transaction._();

  @override
  int compareTo(Transaction other) => -createdAt.compareTo(other.createdAt);
}
