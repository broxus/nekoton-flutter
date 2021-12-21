import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  @HiveType(typeId: 35)
  const factory MultisigTransaction.send({
    @HiveField(0) required MultisigSendTransaction multisigSendTransaction,
  }) = _Send;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  @HiveType(typeId: 36)
  const factory MultisigTransaction.submit({
    @HiveField(0) required MultisigSubmitTransaction multisigSubmitTransaction,
  }) = _Submit;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  @HiveType(typeId: 37)
  const factory MultisigTransaction.confirm({
    @HiveField(0) required MultisigConfirmTransaction multisigConfirmTransaction,
  }) = _Confirm;

  factory MultisigTransaction.fromJson(Map<String, dynamic> json) => _$MultisigTransactionFromJson(json);
}
