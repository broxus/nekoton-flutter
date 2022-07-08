import 'package:freezed_annotation/freezed_annotation.dart';

part 'multisig_submit_transaction.freezed.dart';
part 'multisig_submit_transaction.g.dart';

@freezed
class MultisigSubmitTransaction with _$MultisigSubmitTransaction {
  const factory MultisigSubmitTransaction({
    required String custodian,
    required String dest,
    required String value,
    required bool bounce,
    required bool allBalance,
    required String payload,
    required String transId,
  }) = _MultisigSubmitTransaction;

  factory MultisigSubmitTransaction.fromJson(Map<String, dynamic> json) =>
      _$MultisigSubmitTransactionFromJson(json);
}
