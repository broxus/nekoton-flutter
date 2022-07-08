import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/models/transactions_batch_type.dart';

part 'transactions_batch_info.freezed.dart';
part 'transactions_batch_info.g.dart';

@freezed
class TransactionsBatchInfo with _$TransactionsBatchInfo {
  const factory TransactionsBatchInfo({
    required String minLt,
    required String maxLt,
    required TransactionsBatchType batchType,
  }) = _TransactionsBatchInfo;

  factory TransactionsBatchInfo.fromJson(Map<String, dynamic> json) =>
      _$TransactionsBatchInfoFromJson(json);
}
