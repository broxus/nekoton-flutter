import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'message_body.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  @JsonSerializable(explicitToJson: true)
  const factory Message({
    String? src,
    String? dst,
    required String value,
    MessageBody? body,
    required bool bounce,
    required bool bounced,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}
