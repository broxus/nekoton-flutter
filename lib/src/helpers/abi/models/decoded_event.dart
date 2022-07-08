import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/tokens_object.dart';

part 'decoded_event.freezed.dart';
part 'decoded_event.g.dart';

@freezed
class DecodedEvent with _$DecodedEvent {
  const factory DecodedEvent({
    required String event,
    required TokensObject data,
  }) = _DecodedEvent;

  factory DecodedEvent.fromJson(Map<String, dynamic> json) => _$DecodedEventFromJson(json);
}
