import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'de_pool_receive_answer_notification.freezed.dart';
part 'de_pool_receive_answer_notification.g.dart';

@freezed
class DePoolReceiveAnswerNotification with _$DePoolReceiveAnswerNotification {
  @HiveType(typeId: 27)
  const factory DePoolReceiveAnswerNotification({
    @HiveField(0) required int errorCode,
    @HiveField(1) required String comment,
  }) = _DePoolReceiveAnswerNotification;

  factory DePoolReceiveAnswerNotification.fromJson(Map<String, dynamic> json) =>
      _$DePoolReceiveAnswerNotificationFromJson(json);
}
