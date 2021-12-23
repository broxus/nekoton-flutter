import 'package:freezed_annotation/freezed_annotation.dart';

part 'internal_message.freezed.dart';
part 'internal_message.g.dart';

@freezed
class InternalMessage with _$InternalMessage {
  const factory InternalMessage({
    String? source,
    required String destination,
    required String amount,
    required bool bounce,
    required String body,
  }) = _InternalMessage;

  factory InternalMessage.fromJson(Map<String, dynamic> json) => _$InternalMessageFromJson(json);
}
