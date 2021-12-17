import 'package:freezed_annotation/freezed_annotation.dart';

part 'adnl_config.freezed.dart';
part 'adnl_config.g.dart';

@freezed
class AdnlConfig with _$AdnlConfig {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AdnlConfig({
    required String serverAddress,
    required String serverKey,
    required int maxConnectionCount,
    int? minIdleConnectionCount,
    @JsonKey(
      fromJson: AdnlConfig._rustDurationFromSecondsFromJson,
      toJson: AdnlConfig._rustDurationFromSecondsToJson,
    )
        required int socketReadTimeout,
    @JsonKey(
      fromJson: AdnlConfig._rustDurationFromSecondsFromJson,
      toJson: AdnlConfig._rustDurationFromSecondsToJson,
    )
        required int socketSendTimeout,
    @JsonKey(
      fromJson: AdnlConfig._rustDurationFromSecondsFromJson,
      toJson: AdnlConfig._rustDurationFromSecondsToJson,
    )
        required int lastBlockThreshold,
    @JsonKey(
      fromJson: AdnlConfig._rustDurationFromSecondsFromJson,
      toJson: AdnlConfig._rustDurationFromSecondsToJson,
    )
        required int pingTimeout,
  }) = _AdnlConfig;

  factory AdnlConfig.fromJson(Map<String, dynamic> json) => _$AdnlConfigFromJson(json);

  static int _rustDurationFromSecondsFromJson(Map<String, dynamic> json) {
    final secs = json['secs'] as String;
    return int.parse(secs);
  }

  static Map<String, dynamic> _rustDurationFromSecondsToJson(int secs) {
    final json = {'secs': secs, 'nanos': 0};
    return json;
  }
}
