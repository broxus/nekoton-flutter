import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_id.freezed.dart';
part 'transaction_id.g.dart';

@freezed
class TransactionId with _$TransactionId {
  const factory TransactionId({
    required String lt,
    required String hash,
  }) = _TransactionId;

  factory TransactionId.fromJson(Map<String, dynamic> json) => _$TransactionIdFromJson(json);
}
