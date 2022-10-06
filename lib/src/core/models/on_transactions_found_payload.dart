import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/transactions_batch_info.dart';
import 'transaction.dart';

part 'on_transactions_found_payload.freezed.dart';
part 'on_transactions_found_payload.g.dart';

@freezed
class OnTransactionsFoundPayload with _$OnTransactionsFoundPayload {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory OnTransactionsFoundPayload({
    required List<Transaction> transactions,
    required TransactionsBatchInfo batchInfo,
  }) = _OnTransactionsFoundPayload;

  factory OnTransactionsFoundPayload.fromJson(Map<String, dynamic> json) =>
      _$OnTransactionsFoundPayloadFromJson(json);
}
