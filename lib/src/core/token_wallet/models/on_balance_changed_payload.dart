import 'package:freezed_annotation/freezed_annotation.dart';

part 'on_balance_changed_payload.freezed.dart';
part 'on_balance_changed_payload.g.dart';

@freezed
class OnBalanceChangedPayload with _$OnBalanceChangedPayload {
  const factory OnBalanceChangedPayload({
    required String balance,
  }) = _OnBalanceChangedPayload;

  factory OnBalanceChangedPayload.fromJson(Map<String, dynamic> json) =>
      _$OnBalanceChangedPayloadFromJson(json);
}
