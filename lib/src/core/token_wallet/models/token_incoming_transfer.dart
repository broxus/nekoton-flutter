import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_incoming_transfer.freezed.dart';
part 'token_incoming_transfer.g.dart';

@freezed
class TokenIncomingTransfer with _$TokenIncomingTransfer {
  const factory TokenIncomingTransfer({
    required String tokens,
    required String senderAddress,
  }) = _TokenIncomingTransfer;

  factory TokenIncomingTransfer.fromJson(Map<String, dynamic> json) =>
      _$TokenIncomingTransferFromJson(json);
}
