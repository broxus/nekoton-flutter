import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/transaction.dart';

part 'get_transaction_output.freezed.dart';
part 'get_transaction_output.g.dart';

@freezed
class GetTransactionOutput with _$GetTransactionOutput {
  @JsonSerializable(explicitToJson: true)
  const factory GetTransactionOutput({
    @JsonKey(includeIfNull: false) Transaction? transaction,
  }) = _GetTransactionOutput;

  factory GetTransactionOutput.fromJson(Map<String, dynamic> json) => _$GetTransactionOutputFromJson(json);
}
