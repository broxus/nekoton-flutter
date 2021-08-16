import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transactions_batch_info.freezed.dart';
part 'transactions_batch_info.g.dart';

@freezed
class TransactionsBatchInfo with _$TransactionsBatchInfo {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TransactionsBatchInfo({
    required String minLt,
    required String maxLt,
    required bool old,
  }) = _TransactionsBatchInfo;

  factory TransactionsBatchInfo.fromJson(Map<String, dynamic> json) => _$TransactionsBatchInfoFromJson(json);
}
