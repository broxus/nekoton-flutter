import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_data.freezed.dart';

@freezed
class ConnectionData with _$ConnectionData {
  const factory ConnectionData({
    required String name,
    required String group,
    required String type,
    required String endpoint,
    required int timeout,
  }) = _ConnectionData;
}
