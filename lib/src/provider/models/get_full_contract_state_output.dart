import 'package:freezed_annotation/freezed_annotation.dart';

import 'full_contract_state.dart';

part 'get_full_contract_state_output.freezed.dart';
part 'get_full_contract_state_output.g.dart';

@freezed
class GetFullContractStateOutput with _$GetFullContractStateOutput {
  @JsonSerializable(explicitToJson: true)
  const factory GetFullContractStateOutput({
    FullContractState? state,
  }) = _GetFullContractStateOutput;

  factory GetFullContractStateOutput.fromJson(Map<String, dynamic> json) => _$GetFullContractStateOutputFromJson(json);
}
