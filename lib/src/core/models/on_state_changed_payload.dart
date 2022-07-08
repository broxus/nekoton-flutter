import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/models/contract_state.dart';

part 'on_state_changed_payload.freezed.dart';
part 'on_state_changed_payload.g.dart';

@freezed
class OnStateChangedPayload with _$OnStateChangedPayload {
  const factory OnStateChangedPayload({
    required ContractState newState,
  }) = _OnStateChangedPayload;

  factory OnStateChangedPayload.fromJson(Map<String, dynamic> json) =>
      _$OnStateChangedPayloadFromJson(json);
}
