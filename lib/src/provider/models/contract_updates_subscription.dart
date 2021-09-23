import 'package:freezed_annotation/freezed_annotation.dart';

part 'contract_updates_subscription.freezed.dart';
part 'contract_updates_subscription.g.dart';

@freezed
class ContractUpdatesSubscription with _$ContractUpdatesSubscription {
  @JsonSerializable()
  const factory ContractUpdatesSubscription({
    bool? state,
    bool? transactions,
  }) = _ContractUpdatesSubscription;

  factory ContractUpdatesSubscription.fromJson(Map<String, dynamic> json) =>
      _$ContractUpdatesSubscriptionFromJson(json);
}
