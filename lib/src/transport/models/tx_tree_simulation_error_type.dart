import 'package:freezed_annotation/freezed_annotation.dart';

part 'tx_tree_simulation_error_type.g.dart';

@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum TxTreeSimulationErrorType {
  computePhase,
  actionPhase,
  frozen,
  deleted;

  @override
  String toString() => _$TxTreeSimulationErrorTypeEnumMap[this]!;
}
