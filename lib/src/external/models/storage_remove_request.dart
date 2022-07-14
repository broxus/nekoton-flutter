import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_remove_request.freezed.dart';
part 'storage_remove_request.g.dart';

@freezed
class StorageRemoveRequest with _$StorageRemoveRequest {
  const factory StorageRemoveRequest({
    required String tx,
    required String key,
  }) = _StorageRemoveRequest;

  factory StorageRemoveRequest.fromJson(Map<String, dynamic> json) =>
      _$StorageRemoveRequestFromJson(json);
}
