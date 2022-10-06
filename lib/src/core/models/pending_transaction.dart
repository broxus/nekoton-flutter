import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_transaction.freezed.dart';
part 'pending_transaction.g.dart';

@freezed
class PendingTransaction with _$PendingTransaction implements Comparable<PendingTransaction> {
  const factory PendingTransaction({
    required String messageHash,
    String? src,
    required int expireAt,
  }) = _PendingTransaction;

  factory PendingTransaction.fromJson(Map<String, dynamic> json) =>
      _$PendingTransactionFromJson(json);

  const PendingTransaction._();

  @override
  int compareTo(PendingTransaction other) => -expireAt.compareTo(other.expireAt);
}
