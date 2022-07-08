import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/transfer_recipient.dart';

part 'token_outgoing_transfer.freezed.dart';
part 'token_outgoing_transfer.g.dart';

@freezed
class TokenOutgoingTransfer with _$TokenOutgoingTransfer {
  const factory TokenOutgoingTransfer({
    required TransferRecipient to,
    required String tokens,
  }) = _TokenOutgoingTransfer;

  factory TokenOutgoingTransfer.fromJson(Map<String, dynamic> json) =>
      _$TokenOutgoingTransferFromJson(json);
}
