import 'package:freezed_annotation/freezed_annotation.dart';

part 'signed_message.freezed.dart';
part 'signed_message.g.dart';

@freezed
class SignedMessage with _$SignedMessage {
  const factory SignedMessage({
    required String hash,
    required int expireAt,
    required String boc,
  }) = _SignedMessage;

  factory SignedMessage.fromJson(Map<String, dynamic> json) => _$SignedMessageFromJson(json);
}
