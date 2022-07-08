import 'package:freezed_annotation/freezed_annotation.dart';

part 'multisig_confirm_transaction.freezed.dart';
part 'multisig_confirm_transaction.g.dart';

@freezed
class MultisigConfirmTransaction with _$MultisigConfirmTransaction {
  const factory MultisigConfirmTransaction({
    required String custodian,
    required String transactionId,
  }) = _MultisigConfirmTransaction;

  factory MultisigConfirmTransaction.fromJson(Map<String, dynamic> json) =>
      _$MultisigConfirmTransactionFromJson(json);
}
