import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/models/transaction.dart';
import 'method_name.dart';

part 'decode_transaction_input.freezed.dart';
part 'decode_transaction_input.g.dart';

@freezed
class DecodeTransactionInput with _$DecodeTransactionInput {
  const factory DecodeTransactionInput({
    required Transaction transaction,
    required String abi,
    required MethodName method,
  }) = _DecodeTransactionInput;

  factory DecodeTransactionInput.fromJson(Map<String, dynamic> json) => _$DecodeTransactionInputFromJson(json);
}
