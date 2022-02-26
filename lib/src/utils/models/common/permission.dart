import 'package:freezed_annotation/freezed_annotation.dart';

enum Permission {
  @JsonValue('basic')
  basic,
  @JsonValue('accountInteraction')
  accountInteraction,
}
