import 'package:freezed_annotation/freezed_annotation.dart';

import 'wallet_contract_type.dart';

part 'account_interaction.freezed.dart';
part 'account_interaction.g.dart';

@freezed
class AccountInteraction with _$AccountInteraction {
  @JsonSerializable()
  const factory AccountInteraction({
    required String address,
    required String publicKey,
    required WalletContractType contractType,
  }) = _AccountInteraction;

  factory AccountInteraction.fromJson(Map<String, dynamic> json) => _$AccountInteractionFromJson(json);
}
