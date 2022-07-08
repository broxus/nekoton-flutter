import 'package:freezed_annotation/freezed_annotation.dart';

part 'jrpc_network_settings.freezed.dart';
part 'jrpc_network_settings.g.dart';

@freezed
class JrpcNetworkSettings with _$JrpcNetworkSettings {
  const factory JrpcNetworkSettings({
    required String endpoint,
  }) = _JrpcNetworkSettings;

  factory JrpcNetworkSettings.fromJson(Map<String, dynamic> json) =>
      _$JrpcNetworkSettingsFromJson(json);
}
