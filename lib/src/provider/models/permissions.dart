import 'package:freezed_annotation/freezed_annotation.dart';

import 'account_interaction.dart';

part 'permissions.freezed.dart';
part 'permissions.g.dart';

@freezed
class Permissions with _$Permissions {
  @JsonSerializable(explicitToJson: true)
  const factory Permissions({
    bool? tonClient,
    AccountInteraction? accountInteraction,
  }) = _Permissions;

  factory Permissions.fromJson(Map<String, dynamic> json) => _$PermissionsFromJson(json);
}
