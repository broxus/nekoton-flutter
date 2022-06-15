import 'package:freezed_annotation/freezed_annotation.dart';

import 'existing_contract.dart';

part 'raw_contract_state.freezed.dart';
part 'raw_contract_state.g.dart';

@Freezed(unionKey: 'type')
class RawContractState with _$RawContractState {
  const factory RawContractState.notExists() = _RawContractStateNotExists;

  const factory RawContractState.exists(ExistingContract data) = _RawContractStateExists;

  factory RawContractState.fromJson(Map<String, dynamic> json) => _$RawContractStateFromJson(json);
}
