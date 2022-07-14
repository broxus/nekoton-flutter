import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_set_request.freezed.dart';
part 'storage_set_request.g.dart';

@freezed
class StorageSetRequest with _$StorageSetRequest {
  const factory StorageSetRequest({
    required String tx,
    required String key,
    required String value,
  }) = _StorageSetRequest;

  factory StorageSetRequest.fromJson(Map<String, dynamic> json) =>
      _$StorageSetRequestFromJson(json);
}
