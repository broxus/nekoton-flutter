import 'package:freezed_annotation/freezed_annotation.dart';

part 'proto_network_settings.freezed.dart';
part 'proto_network_settings.g.dart';

@freezed
abstract class ProtoNetworkSettings with _$ProtoNetworkSettings {
  const factory ProtoNetworkSettings({
    required String endpoint,
  }) = _ProtoNetworkSettings;

  factory ProtoNetworkSettings.fromJson(Map<String, dynamic> json) =>
      _$ProtoNetworkSettingsFromJson(json);
}
