import 'package:freezed_annotation/freezed_annotation.dart';

import 'tokens_object.dart';

part 'decoded_transaction_event.freezed.dart';
part 'decoded_transaction_event.g.dart';

@freezed
class DecodedTransactionEvent with _$DecodedTransactionEvent {
  const factory DecodedTransactionEvent({
    required String event,
    required TokensObject data,
  }) = _DecodedTransactionEvent;

  factory DecodedTransactionEvent.fromJson(Map<String, dynamic> json) =>
      _$DecodedTransactionEventFromJson(json);
}
