import 'package:freezed_annotation/freezed_annotation.dart';

enum EthEventStatus {
  @JsonValue('InProcess')
  inProcess,
  @JsonValue('Confirmed')
  confirmed,
  @JsonValue('Executed')
  executed,
  @JsonValue('Rejected')
  rejected,
}
