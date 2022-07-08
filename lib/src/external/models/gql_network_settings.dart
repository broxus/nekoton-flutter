import 'package:freezed_annotation/freezed_annotation.dart';

part 'gql_network_settings.freezed.dart';
part 'gql_network_settings.g.dart';

@freezed
class GqlNetworkSettings with _$GqlNetworkSettings {
  const factory GqlNetworkSettings({
    required List<String> endpoints,
    required int latencyDetectionInterval,
    required int maxLatency,
    required int endpointSelectionRetryCount,
    required bool local,
  }) = _GqlNetworkSettings;

  factory GqlNetworkSettings.fromJson(Map<String, dynamic> json) =>
      _$GqlNetworkSettingsFromJson(json);
}
