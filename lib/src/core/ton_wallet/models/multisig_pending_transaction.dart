import 'package:freezed_annotation/freezed_annotation.dart';

part 'multisig_pending_transaction.freezed.dart';
part 'multisig_pending_transaction.g.dart';

@freezed
class MultisigPendingTransaction with _$MultisigPendingTransaction {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory MultisigPendingTransaction({
    required String id,
    required List<String> confirmations,
    required int signsRequired,
    required int signsReceived,
    required String creator,
    required int index,
    required String dest,
    required String value,
    required int sendFlags,
    required String payload,
    required bool bounce,
  }) = _MultisigPendingTransaction;

  factory MultisigPendingTransaction.fromJson(Map<String, dynamic> json) =>
      _$MultisigPendingTransactionFromJson(json);
}
