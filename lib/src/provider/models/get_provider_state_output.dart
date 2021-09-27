import 'package:freezed_annotation/freezed_annotation.dart';

import 'contract_updates_subscription.dart';
import 'permissions.dart';

part 'get_provider_state_output.freezed.dart';
part 'get_provider_state_output.g.dart';

@freezed
class GetProviderStateOutput with _$GetProviderStateOutput {
  @JsonSerializable(explicitToJson: true)
  const factory GetProviderStateOutput({
    required String version,
    required int numericVersion,
    required String selectedConnection,
    Permissions? permissions,
    required Map<String, ContractUpdatesSubscription> subscriptions,
  }) = _GetProviderStateOutput;

  factory GetProviderStateOutput.fromJson(Map<String, dynamic> json) => _$GetProviderStateOutputFromJson(json);
}
