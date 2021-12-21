import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'known_payload.dart';
import 'wallet_interaction_method.dart';

part 'wallet_interaction_info.freezed.dart';
part 'wallet_interaction_info.g.dart';

@freezed
class WalletInteractionInfo with _$WalletInteractionInfo {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  @HiveType(typeId: 48)
  const factory WalletInteractionInfo({
    @HiveField(0) required String? recipient,
    @HiveField(1) required KnownPayload? knownPayload,
    @HiveField(2) required WalletInteractionMethod method,
  }) = _WalletInteractionInfo;

  factory WalletInteractionInfo.fromJson(Map<String, dynamic> json) => _$WalletInteractionInfoFromJson(json);
}
