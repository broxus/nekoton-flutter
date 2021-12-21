import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'multisig_confirm_transaction.freezed.dart';
part 'multisig_confirm_transaction.g.dart';

@freezed
class MultisigConfirmTransaction with _$MultisigConfirmTransaction {
  @HiveType(typeId: 32)
  const factory MultisigConfirmTransaction({
    @HiveField(0) required String custodian,
    @HiveField(1) required String transactionId,
  }) = _MultisigConfirmTransaction;

  factory MultisigConfirmTransaction.fromJson(Map<String, dynamic> json) => _$MultisigConfirmTransactionFromJson(json);
}
