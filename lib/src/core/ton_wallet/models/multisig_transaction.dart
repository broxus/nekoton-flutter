import 'package:freezed_annotation/freezed_annotation.dart';

import 'multisig_confirm_transaction.dart';
import 'multisig_send_transaction.dart';
import 'multisig_submit_transaction.dart';

part 'multisig_transaction.freezed.dart';
part 'multisig_transaction.g.dart';

@Freezed(unionKey: 'type')
class MultisigTransaction with _$MultisigTransaction {
  const factory MultisigTransaction.send(MultisigSendTransaction data) = _MultisigTransactionSend;

  const factory MultisigTransaction.submit(MultisigSubmitTransaction data) = _MultisigTransactionSubmit;

  const factory MultisigTransaction.confirm(MultisigConfirmTransaction data) = _MultisigTransactionConfirm;

  factory MultisigTransaction.fromJson(Map<String, dynamic> json) => _$MultisigTransactionFromJson(json);
}
