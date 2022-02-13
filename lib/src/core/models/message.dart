import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  @HiveType(typeId: 11)
  const factory Message({
    @HiveField(0) required String hash,
    @HiveField(1) String? src,
    @HiveField(2) String? dst,
    @HiveField(3) required String value,
    @HiveField(4) required bool bounce,
    @HiveField(5) required bool bounced,
    @HiveField(6) String? body,
    @HiveField(7) String? bodyHash,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}
