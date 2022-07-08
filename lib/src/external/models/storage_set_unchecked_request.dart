import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_set_unchecked_request.freezed.dart';
part 'storage_set_unchecked_request.g.dart';

@freezed
class StorageSetUncheckedRequest with _$StorageSetUncheckedRequest {
  const factory StorageSetUncheckedRequest({
    required String key,
    required String value,
  }) = _StorageSetUncheckedRequest;

  factory StorageSetUncheckedRequest.fromJson(Map<String, dynamic> json) =>
      _$StorageSetUncheckedRequestFromJson(json);
}
