import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/models/gen_timings.dart';
import '../../core/models/last_transaction_id.dart';

part 'existing_contract.freezed.dart';
part 'existing_contract.g.dart';

@freezed
class ExistingContract with _$ExistingContract {
  const factory ExistingContract({
    required String account,
    required GenTimings timings,
    required LastTransactionId lastTransactionId,
  }) = _ExistingContract;

  factory ExistingContract.fromJson(Map<String, dynamic> json) => _$ExistingContractFromJson(json);
}
