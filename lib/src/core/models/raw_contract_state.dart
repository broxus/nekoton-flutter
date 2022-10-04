import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/models/existing_contract.dart';

part 'raw_contract_state.freezed.dart';
part 'raw_contract_state.g.dart';

@Freezed(unionKey: 'type')
class RawContractState with _$RawContractState {
  const factory RawContractState.notExists() = _NotExists;

  const factory RawContractState.exists(ExistingContract data) = _Exists;

  factory RawContractState.fromJson(Map<String, dynamic> json) => _$RawContractStateFromJson(json);
}
