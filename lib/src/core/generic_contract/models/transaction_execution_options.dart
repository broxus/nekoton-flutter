import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_execution_options.freezed.dart';
part 'transaction_execution_options.g.dart';

@freezed
class TransactionExecutionOptions with _$TransactionExecutionOptions {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TransactionExecutionOptions({
    required bool disableSignatureCheck,
  }) = _TransactionExecutionOptions;

  factory TransactionExecutionOptions.fromJson(Map<String, dynamic> json) =>
      _$TransactionExecutionOptionsFromJson(json);
}