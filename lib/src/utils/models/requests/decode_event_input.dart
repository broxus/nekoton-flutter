import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/method_name.dart';

part 'decode_event_input.freezed.dart';
part 'decode_event_input.g.dart';

@freezed
class DecodeEventInput with _$DecodeEventInput {
  const factory DecodeEventInput({
    required String body,
    required String abi,
    required MethodName event,
  }) = _DecodeEventInput;

  factory DecodeEventInput.fromJson(Map<String, dynamic> json) => _$DecodeEventInputFromJson(json);
}
