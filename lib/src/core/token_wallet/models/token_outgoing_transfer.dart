import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'transfer_recipient.dart';

part 'token_outgoing_transfer.freezed.dart';
part 'token_outgoing_transfer.g.dart';

@freezed
class TokenOutgoingTransfer with _$TokenOutgoingTransfer {
  @JsonSerializable()
  const factory TokenOutgoingTransfer({
    required TransferRecipient to,
    required String tokens,
  }) = _TokenOutgoingTransfer;

  factory TokenOutgoingTransfer.fromJson(Map<String, dynamic> json) => _$TokenOutgoingTransferFromJson(json);
}