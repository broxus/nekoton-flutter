import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/models/gen_timings.dart';
import 'package:nekoton_flutter/src/core/models/last_transaction_id.dart';

part 'contract_state.freezed.dart';
part 'contract_state.g.dart';

@freezed
class ContractState with _$ContractState {
  const factory ContractState({
    required String balance,
    required GenTimings genTimings,
    LastTransactionId? lastTransactionId,
    required bool isDeployed,
    String? codeHash,
  }) = _ContractState;

  factory ContractState.fromJson(Map<String, dynamic> json) => _$ContractStateFromJson(json);
}
