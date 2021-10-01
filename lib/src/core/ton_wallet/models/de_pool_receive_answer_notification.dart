import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'de_pool_receive_answer_notification.freezed.dart';
part 'de_pool_receive_answer_notification.g.dart';

@freezed
class DePoolReceiveAnswerNotification with _$DePoolReceiveAnswerNotification {
  @JsonSerializable()
  const factory DePoolReceiveAnswerNotification({
    required int errorCode,
    required String comment,
  }) = _DePoolReceiveAnswerNotification;

  factory DePoolReceiveAnswerNotification.fromJson(Map<String, dynamic> json) =>
      _$DePoolReceiveAnswerNotificationFromJson(json);
}
