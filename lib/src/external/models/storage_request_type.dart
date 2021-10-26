import 'package:json_annotation/json_annotation.dart';

enum StorageRequestType {
  @JsonValue('Get')
  get,
  @JsonValue('Set')
  set,
  @JsonValue('Remove')
  remove,
}
