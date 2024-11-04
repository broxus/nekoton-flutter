import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/transport/models/tx_tree_simulation_error_type.dart';

part 'tx_tree_simulation_error.freezed.dart';
part 'tx_tree_simulation_error.g.dart';

@freezed
class TxTreeSimulationError with _$TxTreeSimulationError {
  const factory TxTreeSimulationError({
    required TxTreeSimulationErrorType type,
    num? code,
  }) = _TxTreeSimulationError;

  factory TxTreeSimulationError.fromJson(Map<String, dynamic> json) =>
      _$TxTreeSimulationErrorFromJson(json);
}
