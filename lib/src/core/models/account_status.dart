import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum AccountStatus {
  uninit,
  frozen,
  active,
  nonexist,
}
