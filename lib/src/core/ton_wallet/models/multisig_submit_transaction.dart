import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'multisig_submit_transaction.freezed.dart';
part 'multisig_submit_transaction.g.dart';

@freezed
class MultisigSubmitTransaction with _$MultisigSubmitTransaction {
  @HiveType(typeId: 34)
  const factory MultisigSubmitTransaction({
    @HiveField(0) required String custodian,
    @HiveField(1) required String dest,
    @HiveField(2) required String value,
    @HiveField(3) required bool bounce,
    @HiveField(4) required bool allBalance,
    @HiveField(5) required String payload,
    @HiveField(6) required String transId,
  }) = _MultisigSubmitTransaction;

  factory MultisigSubmitTransaction.fromJson(Map<String, dynamic> json) => _$MultisigSubmitTransactionFromJson(json);
}
