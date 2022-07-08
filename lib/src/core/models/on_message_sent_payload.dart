import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/models/pending_transaction.dart';
import 'package:nekoton_flutter/src/core/models/transaction.dart';

part 'on_message_sent_payload.freezed.dart';
part 'on_message_sent_payload.g.dart';

@freezed
class OnMessageSentPayload with _$OnMessageSentPayload {
  const factory OnMessageSentPayload({
    required PendingTransaction pendingTransaction,
    Transaction? transaction,
  }) = _OnMessageSentPayload;

  factory OnMessageSentPayload.fromJson(Map<String, dynamic> json) =>
      _$OnMessageSentPayloadFromJson(json);
}
