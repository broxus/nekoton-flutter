import 'package:freezed_annotation/freezed_annotation.dart';

import 'multisig_transaction.dart';

part 'wallet_interaction_method.freezed.dart';
part 'wallet_interaction_method.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class WalletInteractionMethod with _$WalletInteractionMethod {
  @JsonSerializable()
  const factory WalletInteractionMethod.walletV3Transfer() = _WalletV3Transfer;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory WalletInteractionMethod.multisig({
    required MultisigTransaction multisigTransaction,
  }) = _Multisig;

  factory WalletInteractionMethod.fromJson(Map<String, dynamic> json) => _$WalletInteractionMethodFromJson(json);
}
