import 'package:freezed_annotation/freezed_annotation.dart';

part 'last_transaction_id.freezed.dart';
part 'last_transaction_id.g.dart';

@freezed
class LastTransactionId with _$LastTransactionId {
  const factory LastTransactionId({
    required bool isExact,
    required String lt,
    @JsonKey(includeIfNull: false) String? hash,
  }) = _LastTransactionId;

  factory LastTransactionId.fromJson(Map<String, dynamic> json) =>
      _$LastTransactionIdFromJson(json);
}
