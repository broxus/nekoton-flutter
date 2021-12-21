import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'multisig_send_transaction.freezed.dart';
part 'multisig_send_transaction.g.dart';

@freezed
class MultisigSendTransaction with _$MultisigSendTransaction {
  @HiveType(typeId: 33)
  const factory MultisigSendTransaction({
    @HiveField(0) required String dest,
    @HiveField(1) required String value,
    @HiveField(2) required bool bounce,
    @HiveField(3) required int flags,
    @HiveField(4) required String payload,
  }) = _MultisigSendTransaction;

  factory MultisigSendTransaction.fromJson(Map<String, dynamic> json) => _$MultisigSendTransactionFromJson(json);
}
