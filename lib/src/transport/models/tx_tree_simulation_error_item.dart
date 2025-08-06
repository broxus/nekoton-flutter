import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/transport/models/tx_tree_simulation_error.dart';

part 'tx_tree_simulation_error_item.freezed.dart';
part 'tx_tree_simulation_error_item.g.dart';

@freezed
abstract class TxTreeSimulationErrorItem with _$TxTreeSimulationErrorItem {
  const factory TxTreeSimulationErrorItem({
    required String address,
    required TxTreeSimulationError error,
  }) = _TxTreeSimulationErrorItem;

  factory TxTreeSimulationErrorItem.fromJson(Map<String, dynamic> json) =>
      _$TxTreeSimulationErrorItemFromJson(json);
}
