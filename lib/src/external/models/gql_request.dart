import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gql_request.freezed.dart';
part 'gql_request.g.dart';

@freezed
class GqlRequest with _$GqlRequest {
  @JsonSerializable()
  const factory GqlRequest({
    required BigInt tx,
    required String data,
  }) = _GqlRequest;

  factory GqlRequest.fromJson(Map<String, dynamic> json) => _$GqlRequestFromJson(json);
}
