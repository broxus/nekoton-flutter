import 'package:freezed_annotation/freezed_annotation.dart';

part 'function_call.freezed.dart';
part 'function_call.g.dart';

@freezed
class FunctionCall with _$FunctionCall {
  @JsonSerializable()
  const factory FunctionCall({
    required String abi,
    required String method,
    required Map<String, dynamic> params,
  }) = _FunctionCall;

  factory FunctionCall.fromJson(Map<String, dynamic> json) => _$FunctionCallFromJson(json);
}
