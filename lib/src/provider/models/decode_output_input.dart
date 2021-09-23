import 'package:freezed_annotation/freezed_annotation.dart';

part 'decode_output_input.freezed.dart';
part 'decode_output_input.g.dart';

@freezed
class DecodeOutputInput with _$DecodeOutputInput {
  @JsonSerializable()
  const factory DecodeOutputInput({
    required String body,
    required String abi,
    required dynamic method,
  }) = _DecodeOutputInput;

  factory DecodeOutputInput.fromJson(Map<String, dynamic> json) => _$DecodeOutputInputFromJson(json);
}
