import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pending_transaction.freezed.dart';
part 'pending_transaction.g.dart';

@freezed
class PendingTransaction with _$PendingTransaction {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory PendingTransaction({
    String? src,
    required String bodyHash,
    required int expireAt,
  }) = _PendingTransaction;

  factory PendingTransaction.fromJson(Map<String, dynamic> json) => _$PendingTransactionFromJson(json);
}
