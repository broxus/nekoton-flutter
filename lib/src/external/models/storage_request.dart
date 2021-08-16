import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'storage_request_type.dart';

part 'storage_request.freezed.dart';
part 'storage_request.g.dart';

@freezed
class StorageRequest with _$StorageRequest {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory StorageRequest({
    required int tx,
    required String key,
    String? value,
    required StorageRequestType requestType,
  }) = _StorageRequest;

  factory StorageRequest.fromJson(Map<String, dynamic> json) => _$StorageRequestFromJson(json);
}
