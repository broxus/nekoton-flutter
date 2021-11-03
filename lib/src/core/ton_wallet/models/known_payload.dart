import 'package:freezed_annotation/freezed_annotation.dart';

import '../../token_wallet/models/token_outgoing_transfer.dart';
import '../../token_wallet/models/token_swap_back.dart';

part 'known_payload.freezed.dart';
part 'known_payload.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class KnownPayload with _$KnownPayload {
  const factory KnownPayload.comment({
    required String value,
  }) = _Comment;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory KnownPayload.tokenOutgoingTransfer({
    required TokenOutgoingTransfer tokenOutgoingTransfer,
  }) = _TokenOutgoingTransfer;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory KnownPayload.tokenSwapBack({
    required TokenSwapBack tokenSwapBack,
  }) = _TokenSwapBack;

  factory KnownPayload.fromJson(Map<String, dynamic> json) => _$KnownPayloadFromJson(json);
}
