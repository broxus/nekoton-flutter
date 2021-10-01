import 'package:freezed_annotation/freezed_annotation.dart';

import '../../provider/models/tokens_object.dart';

part 'decoded_transaction.freezed.dart';
part 'decoded_transaction.g.dart';

@freezed
class DecodedTransaction with _$DecodedTransaction {
  @JsonSerializable()
  const factory DecodedTransaction({
    required String method,
    required TokensObject input,
    required TokensObject output,
  }) = _DecodedTransaction;

  factory DecodedTransaction.fromJson(Map<String, dynamic> json) => _$DecodedTransactionFromJson(json);
}
