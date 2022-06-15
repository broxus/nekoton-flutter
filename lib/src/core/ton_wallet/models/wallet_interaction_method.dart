import 'package:freezed_annotation/freezed_annotation.dart';

import 'multisig_transaction.dart';

part 'wallet_interaction_method.freezed.dart';
part 'wallet_interaction_method.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class WalletInteractionMethod with _$WalletInteractionMethod {
  const factory WalletInteractionMethod.walletV3Transfer() = _WalletInteractionMethodWalletV3Transfer;

  const factory WalletInteractionMethod.multisig(MultisigTransaction data) = _WalletInteractionMethodMultisig;

  factory WalletInteractionMethod.fromJson(Map<String, dynamic> json) => _$WalletInteractionMethodFromJson(json);
}
