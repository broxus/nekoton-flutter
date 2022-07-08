import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/multisig_confirm_transaction.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/multisig_send_transaction.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/multisig_submit_transaction.dart';

part 'multisig_transaction.freezed.dart';
part 'multisig_transaction.g.dart';

@Freezed(unionKey: 'type')
class MultisigTransaction with _$MultisigTransaction {
  const factory MultisigTransaction.send(MultisigSendTransaction data) = _MultisigTransactionSend;

  const factory MultisigTransaction.submit(MultisigSubmitTransaction data) =
      _MultisigTransactionSubmit;

  const factory MultisigTransaction.confirm(MultisigConfirmTransaction data) =
      _MultisigTransactionConfirm;

  factory MultisigTransaction.fromJson(Map<String, dynamic> json) =>
      _$MultisigTransactionFromJson(json);
}
