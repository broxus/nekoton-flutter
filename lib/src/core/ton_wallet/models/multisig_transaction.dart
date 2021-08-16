import 'package:freezed_annotation/freezed_annotation.dart';

import 'multisig_confirm_transaction.dart';
import 'multisig_send_transaction.dart';
import 'multisig_submit_transaction.dart';

part 'multisig_transaction.freezed.dart';
part 'multisig_transaction.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class MultisigTransaction with _$MultisigTransaction {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory MultisigTransaction.send({
    required MultisigSendTransaction multisigSendTransaction,
  }) = _Send;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory MultisigTransaction.submit({
    required MultisigSubmitTransaction multisigSubmitTransaction,
  }) = _Submit;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory MultisigTransaction.confirm({
    required MultisigConfirmTransaction multisigConfirmTransaction,
  }) = _Confirm;

  factory MultisigTransaction.fromJson(Map<String, dynamic> json) => _$MultisigTransactionFromJson(json);
}
