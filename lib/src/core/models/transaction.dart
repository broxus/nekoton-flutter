import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'account_status.dart';
import 'message.dart';
import 'transaction_id.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory Transaction({
    required TransactionId id,
    TransactionId? prevTransId,
    required int createdAt,
    required bool aborted,
    int? resultCode,
    required AccountStatus origStatus,
    required AccountStatus endStatus,
    required String totalFees,
    required Message inMsg,
    required List<Message> outMsgs,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
}
