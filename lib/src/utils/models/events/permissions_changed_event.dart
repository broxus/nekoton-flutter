import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/permissions.dart';

part 'permissions_changed_event.freezed.dart';
part 'permissions_changed_event.g.dart';

@freezed
class PermissionsChangedEvent with _$PermissionsChangedEvent {
  @JsonSerializable(explicitToJson: true)
  const factory PermissionsChangedEvent({
    required Permissions permissions,
  }) = _PermissionsChangedEvent;

  factory PermissionsChangedEvent.fromJson(Map<String, dynamic> json) => _$PermissionsChangedEventFromJson(json);
}
