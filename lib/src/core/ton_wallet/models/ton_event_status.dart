import 'package:freezed_annotation/freezed_annotation.dart';

enum TonEventStatus {
  @JsonValue('InProcess')
  inProcess,
  @JsonValue('Confirmed')
  confirmed,
  @JsonValue('Rejected')
  rejected,
}
