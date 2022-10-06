import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'token_incoming_transfer.freezed.dart';
part 'token_incoming_transfer.g.dart';

@freezed
class TokenIncomingTransfer with _$TokenIncomingTransfer {
  @HiveType(typeId: 12)
  const factory TokenIncomingTransfer({
    @HiveField(0) required String tokens,
    @HiveField(1) required String senderAddress,
  }) = _TokenIncomingTransfer;

  factory TokenIncomingTransfer.fromJson(Map<String, dynamic> json) =>
      _$TokenIncomingTransferFromJson(json);
}
