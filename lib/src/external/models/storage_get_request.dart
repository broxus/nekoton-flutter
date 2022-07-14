import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_get_request.freezed.dart';
part 'storage_get_request.g.dart';

@freezed
class StorageGetRequest with _$StorageGetRequest {
  const factory StorageGetRequest({
    required String tx,
    required String key,
  }) = _StorageGetRequest;

  factory StorageGetRequest.fromJson(Map<String, dynamic> json) =>
      _$StorageGetRequestFromJson(json);
}
