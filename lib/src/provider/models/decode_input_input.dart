import 'package:freezed_annotation/freezed_annotation.dart';

import 'method_name.dart';

part 'decode_input_input.freezed.dart';
part 'decode_input_input.g.dart';

@freezed
class DecodeInputInput with _$DecodeInputInput {
  @JsonSerializable()
  const factory DecodeInputInput({
    required String body,
    required String abi,
    required MethodName method,
    required bool internal,
  }) = _DecodeInputInput;

  factory DecodeInputInput.fromJson(Map<String, dynamic> json) => _$DecodeInputInputFromJson(json);
}
