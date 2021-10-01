import 'package:freezed_annotation/freezed_annotation.dart';

import 'tokens_object.dart';

part 'decode_transaction_output.freezed.dart';
part 'decode_transaction_output.g.dart';

@freezed
class DecodeTransactionOutput with _$DecodeTransactionOutput {
  @JsonSerializable()
  const factory DecodeTransactionOutput({
    required String method,
    required TokensObject input,
    required TokensObject output,
  }) = _DecodeTransactionOutput;

  factory DecodeTransactionOutput.fromJson(Map<String, dynamic> json) => _$DecodeTransactionOutputFromJson(json);
}
