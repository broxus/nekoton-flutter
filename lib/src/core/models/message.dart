import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  @HiveType(typeId: 11)
  const factory Message({
    @HiveField(0) String? src,
    @HiveField(1) String? dst,
    @HiveField(2) required String value,
    @HiveField(3) required bool bounce,
    @HiveField(4) required bool bounced,
    @HiveField(5) String? body,
    @HiveField(6) String? bodyHash,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}
