import 'package:freezed_annotation/freezed_annotation.dart';

import 'tokens_object.dart';

part 'event.freezed.dart';
part 'event.g.dart';

@freezed
class Event with _$Event {
  @JsonSerializable()
  const factory Event({
    required String event,
    required TokensObject data,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}
