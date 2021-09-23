import 'package:freezed_annotation/freezed_annotation.dart';

import 'full_contract_state.dart';
import 'function_call.dart';

part 'run_local_input.freezed.dart';
part 'run_local_input.g.dart';

@freezed
class RunLocalInput with _$RunLocalInput {
  @JsonSerializable(explicitToJson: true)
  const factory RunLocalInput({
    required String address,
    FullContractState? cachedState,
    required FunctionCall functionCall,
  }) = _RunLocalInput;

  factory RunLocalInput.fromJson(Map<String, dynamic> json) => _$RunLocalInputFromJson(json);
}
