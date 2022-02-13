import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/models/gen_timings.dart';
import '../../core/models/last_transaction_id.dart';

part 'full_contract_state.freezed.dart';
part 'full_contract_state.g.dart';

@freezed
class FullContractState with _$FullContractState {
  @JsonSerializable(explicitToJson: true)
  const factory FullContractState({
    required String balance,
    required GenTimings genTimings,
    LastTransactionId? lastTransactionId,
    required bool isDeployed,
    required String boc,
  }) = _FullContractState;

  factory FullContractState.fromJson(Map<String, dynamic> json) => _$FullContractStateFromJson(json);
}
