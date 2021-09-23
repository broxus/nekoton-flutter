import 'package:freezed_annotation/freezed_annotation.dart';

part 'decode_transaction_output.freezed.dart';
part 'decode_transaction_output.g.dart';

@freezed
class DecodeTransactionOutput with _$DecodeTransactionOutput {
  @JsonSerializable()
  const factory DecodeTransactionOutput({
    required String method,
    required Map<String, dynamic> input,
    required Map<String, dynamic> output,
  }) = _DecodeTransactionOutput;

  factory DecodeTransactionOutput.fromJson(Map<String, dynamic> json) => _$DecodeTransactionOutputFromJson(json);
}
