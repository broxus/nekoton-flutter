import 'package:freezed_annotation/freezed_annotation.dart';

part 'gql_connection_post_request.freezed.dart';
part 'gql_connection_post_request.g.dart';

@freezed
class GqlConnectionPostRequest with _$GqlConnectionPostRequest {
  const factory GqlConnectionPostRequest({
    required int tx,
    required String data,
  }) = _GqlConnectionPostRequest;

  factory GqlConnectionPostRequest.fromJson(Map<String, dynamic> json) => _$GqlConnectionPostRequestFromJson(json);
}
