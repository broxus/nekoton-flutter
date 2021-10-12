import 'package:freezed_annotation/freezed_annotation.dart';

import '../../helpers/models/decoded_transaction_event.dart';

part 'decode_transaction_events_output.freezed.dart';
part 'decode_transaction_events_output.g.dart';

@freezed
class DecodeTransactionEventsOutput with _$DecodeTransactionEventsOutput {
  @JsonSerializable()
  const factory DecodeTransactionEventsOutput({
    required List<DecodedTransactionEvent> events,
  }) = _DecodeTransactionEventsOutput;

  factory DecodeTransactionEventsOutput.fromJson(Map<String, dynamic> json) =>
      _$DecodeTransactionEventsOutputFromJson(json);
}
