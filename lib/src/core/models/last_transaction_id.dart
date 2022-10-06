import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'last_transaction_id.freezed.dart';
part 'last_transaction_id.g.dart';

@freezed
class LastTransactionId with _$LastTransactionId {
  @HiveType(typeId: 215)
  const factory LastTransactionId({
    @HiveField(0) required bool isExact,
    @HiveField(1) required String lt,
    @HiveField(2) String? hash,
  }) = _LastTransactionId;

  factory LastTransactionId.fromJson(Map<String, dynamic> json) =>
      _$LastTransactionIdFromJson(json);
}
