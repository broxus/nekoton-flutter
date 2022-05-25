import 'package:freezed_annotation/freezed_annotation.dart';

import 'existing_contract.dart';

part 'raw_contract_state.freezed.dart';
part 'raw_contract_state.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class RawContractState with _$RawContractState {
  const factory RawContractState.notExists() = _RawContractStateNotExists;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory RawContractState.exists({
    required ExistingContract existingContract,
  }) = _RawContractStateExists;

  factory RawContractState.fromJson(Map<String, dynamic> json) => _$RawContractStateFromJson(json);
}
