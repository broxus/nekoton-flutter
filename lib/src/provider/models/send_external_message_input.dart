import 'package:freezed_annotation/freezed_annotation.dart';

import 'function_call.dart';

part 'send_external_message_input.freezed.dart';
part 'send_external_message_input.g.dart';

@freezed
class SendExternalMessageInput with _$SendExternalMessageInput {
  @JsonSerializable()
  const factory SendExternalMessageInput({
    required String publicKey,
    required String recipient,
    String? stateInit,
    required FunctionCall payload,
    bool? local,
  }) = _SendExternalMessageInput;

  factory SendExternalMessageInput.fromJson(Map<String, dynamic> json) => _$SendExternalMessageInputFromJson(json);
}
