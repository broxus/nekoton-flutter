import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_remove_unchecked_request.freezed.dart';
part 'storage_remove_unchecked_request.g.dart';

@freezed
class StorageRemoveUncheckedRequest with _$StorageRemoveUncheckedRequest {
  const factory StorageRemoveUncheckedRequest({
    required String key,
  }) = _StorageRemoveUncheckedRequest;

  factory StorageRemoveUncheckedRequest.fromJson(Map<String, dynamic> json) =>
      _$StorageRemoveUncheckedRequestFromJson(json);
}
