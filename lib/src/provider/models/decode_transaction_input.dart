import 'package:freezed_annotation/freezed_annotation.dart';

import 'transaction.dart';

part 'decode_transaction_input.freezed.dart';
part 'decode_transaction_input.g.dart';

@freezed
class DecodeTransactionInput with _$DecodeTransactionInput {
  @JsonSerializable()
  const factory DecodeTransactionInput({
    required Transaction transaction,
    required String abi,
    required dynamic method,
  }) = _DecodeTransactionInput;

  factory DecodeTransactionInput.fromJson(Map<String, dynamic> json) => _$DecodeTransactionInputFromJson(json);
}
