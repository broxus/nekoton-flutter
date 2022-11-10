import 'package:freezed_annotation/freezed_annotation.dart';

import 'pending_transaction.dart';
import 'transaction.dart';

part 'on_message_sent_payload.freezed.dart';
part 'on_message_sent_payload.g.dart';

@freezed
class OnMessageSentPayload with _$OnMessageSentPayload {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory OnMessageSentPayload({
    required PendingTransaction pendingTransaction,
    Transaction? transaction,
  }) = _OnMessageSentPayload;

  factory OnMessageSentPayload.fromJson(Map<String, dynamic> json) =>
      _$OnMessageSentPayloadFromJson(json);
}
