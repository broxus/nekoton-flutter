import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_incoming_transfer.freezed.dart';
part 'token_incoming_transfer.g.dart';

@freezed
class TokenIncomingTransfer with _$TokenIncomingTransfer {
  @JsonSerializable()
  const factory TokenIncomingTransfer({
    required String tokens,
    required String senderAddress,
  }) = _TokenIncomingTransfer;

  factory TokenIncomingTransfer.fromJson(Map<String, dynamic> json) => _$TokenIncomingTransferFromJson(json);
}
