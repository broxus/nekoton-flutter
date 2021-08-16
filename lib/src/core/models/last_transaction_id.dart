import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'transaction_id.dart';

part 'last_transaction_id.freezed.dart';
part 'last_transaction_id.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class LastTransactionId with _$LastTransactionId {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory LastTransactionId.exact({
    required TransactionId transactionId,
  }) = _Exact;

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory LastTransactionId.inexact({required String latestLt}) = _Inexact;

  factory LastTransactionId.fromJson(Map<String, dynamic> json) => _$LastTransactionIdFromJson(json);
}
