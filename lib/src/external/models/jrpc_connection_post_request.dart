import 'package:freezed_annotation/freezed_annotation.dart';

part 'jrpc_connection_post_request.freezed.dart';
part 'jrpc_connection_post_request.g.dart';

@freezed
class JrpcConnectionPostRequest with _$JrpcConnectionPostRequest {
  const factory JrpcConnectionPostRequest({
    required int tx,
    required String data,
  }) = _JrpcConnectionPostRequest;

  factory JrpcConnectionPostRequest.fromJson(Map<String, dynamic> json) => _$JrpcConnectionPostRequestFromJson(json);
}
