import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'gen_timings.dart';
import 'last_transaction_id.dart';

part 'contract_state.freezed.dart';
part 'contract_state.g.dart';

@freezed
class ContractState with _$ContractState {
  @JsonSerializable(explicitToJson: true)
  @HiveType(typeId: 217)
  const factory ContractState({
    @HiveField(0) required String balance,
    @HiveField(1) required GenTimings genTimings,
    @HiveField(2) LastTransactionId? lastTransactionId,
    @HiveField(3) required bool isDeployed,
  }) = _ContractState;

  factory ContractState.fromJson(Map<String, dynamic> json) => _$ContractStateFromJson(json);
}
