import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'multisig_transaction.dart';

part 'wallet_interaction_method.freezed.dart';
part 'wallet_interaction_method.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class WalletInteractionMethod with _$WalletInteractionMethod {
  @HiveType(typeId: 49)
  const factory WalletInteractionMethod.walletV3Transfer() =
      _WalletInteractionMethodWalletV3Transfer;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  @HiveType(typeId: 50)
  const factory WalletInteractionMethod.multisig({
    @HiveField(0) required MultisigTransaction multisigTransaction,
  }) = _WalletInteractionMethodMultisig;

  factory WalletInteractionMethod.fromJson(Map<String, dynamic> json) =>
      _$WalletInteractionMethodFromJson(json);
}
