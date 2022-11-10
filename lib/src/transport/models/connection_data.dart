import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:nekoton_flutter/src/transport/models/transport_type.dart';

part 'connection_data.freezed.dart';

@freezed
class ConnectionData with _$ConnectionData {
  const factory ConnectionData({
    required String name,
    required int networkId,
    required String group,
    required TransportType type,
    required List<String> endpoints,
    required int timeout,
    required bool local,
  }) = _ConnectionData;
}
