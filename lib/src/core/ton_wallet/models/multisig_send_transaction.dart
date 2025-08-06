import 'package:freezed_annotation/freezed_annotation.dart';

part 'multisig_send_transaction.freezed.dart';
part 'multisig_send_transaction.g.dart';

@freezed
abstract class MultisigSendTransaction with _$MultisigSendTransaction {
  const factory MultisigSendTransaction({
    required String dest,
    required String value,
    required bool bounce,
    required int flags,
    required String payload,
  }) = _MultisigSendTransaction;

  factory MultisigSendTransaction.fromJson(Map<String, dynamic> json) =>
      _$MultisigSendTransactionFromJson(json);
}
