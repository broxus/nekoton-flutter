import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_handler_message.freezed.dart';
part 'subscription_handler_message.g.dart';

@freezed
class SubscriptionHandlerMessage with _$SubscriptionHandlerMessage {
  const factory SubscriptionHandlerMessage({
    required String event,
    required String payload,
  }) = _SubscriptionHandlerMessage;

  factory SubscriptionHandlerMessage.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionHandlerMessageFromJson(json);
}
