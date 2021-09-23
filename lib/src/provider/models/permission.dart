import 'package:freezed_annotation/freezed_annotation.dart';

enum Permission {
  @JsonValue("tonClient")
  tonClient,
  @JsonValue("accountInteraction")
  accountInteraction,
}
