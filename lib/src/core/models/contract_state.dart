import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'gen_timings.dart';
import 'last_transaction_id.dart';

part 'contract_state.freezed.dart';
part 'contract_state.g.dart';

@freezed
class ContractState with _$ContractState {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory ContractState({
    required String balance,
    required GenTimings genTimings,
    LastTransactionId? lastTransactionId,
    required bool isDeployed,
  }) = _ContractState;

  factory ContractState.fromJson(Map<String, dynamic> json) => _$ContractStateFromJson(json);
}
