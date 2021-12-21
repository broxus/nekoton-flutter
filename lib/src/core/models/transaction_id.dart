import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'transaction_id.freezed.dart';
part 'transaction_id.g.dart';

@freezed
class TransactionId with _$TransactionId {
  @HiveType(typeId: 23)
  const factory TransactionId({
    @HiveField(0) required String lt,
    @HiveField(1) required String hash,
  }) = _TransactionId;

  factory TransactionId.fromJson(Map<String, dynamic> json) => _$TransactionIdFromJson(json);
}
