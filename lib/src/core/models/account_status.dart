import 'package:freezed_annotation/freezed_annotation.dart';

enum AccountStatus {
  @JsonValue('uninit')
  uninit,
  @JsonValue('frozen')
  frozen,
  @JsonValue('active')
  active,
  @JsonValue('nonexist')
  nonexist,
}
