import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../nekoton_flutter.dart';

part 'token_outgoing_transfer.freezed.dart';
part 'token_outgoing_transfer.g.dart';

@freezed
class TokenOutgoingTransfer with _$TokenOutgoingTransfer {
  @HiveType(typeId: 13)
  const factory TokenOutgoingTransfer({
    @HiveField(0) required TransferRecipient to,
    @HiveField(1) required String tokens,
  }) = _TokenOutgoingTransfer;

  factory TokenOutgoingTransfer.fromJson(Map<String, dynamic> json) => _$TokenOutgoingTransferFromJson(json);
}
