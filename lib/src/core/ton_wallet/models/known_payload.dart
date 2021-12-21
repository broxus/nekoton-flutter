import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../token_wallet/models/token_outgoing_transfer.dart';
import '../../token_wallet/models/token_swap_back.dart';

part 'known_payload.freezed.dart';
part 'known_payload.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class KnownPayload with _$KnownPayload {
  @HiveType(typeId: 29)
  const factory KnownPayload.comment({
    @HiveField(0) required String value,
  }) = _KnownPayloadComment;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  @HiveType(typeId: 30)
  const factory KnownPayload.tokenOutgoingTransfer({
    @HiveField(0) required TokenOutgoingTransfer tokenOutgoingTransfer,
  }) = _KnownPayloadTokenOutgoingTransfer;

  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  @HiveType(typeId: 31)
  const factory KnownPayload.tokenSwapBack({
    @HiveField(0) required TokenSwapBack tokenSwapBack,
  }) = _KnownPayloadTokenSwapBack;

  factory KnownPayload.fromJson(Map<String, dynamic> json) => _$KnownPayloadFromJson(json);
}
