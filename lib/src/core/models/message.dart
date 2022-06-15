import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  const factory Message({
    required String hash,
    String? src,
    String? dst,
    required String value,
    required bool bounce,
    required bool bounced,
    String? body,
    String? bodyHash,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}
