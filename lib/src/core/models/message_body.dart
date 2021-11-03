import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_body.freezed.dart';
part 'message_body.g.dart';

@freezed
class MessageBody with _$MessageBody {
  const factory MessageBody({
    required String hash,
    required String data,
  }) = _MessageBody;

  factory MessageBody.fromJson(Map<String, dynamic> json) => _$MessageBodyFromJson(json);
}
