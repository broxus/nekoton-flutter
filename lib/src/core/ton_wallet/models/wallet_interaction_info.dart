import 'package:freezed_annotation/freezed_annotation.dart';

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
  const factory WalletInteractionInfo({
    required String? recipient,
    required KnownPayload? knownPayload,
    required WalletInteractionMethod method,
  }) = _WalletInteractionInfo;

  factory WalletInteractionInfo.fromJson(Map<String, dynamic> json) => _$WalletInteractionInfoFromJson(json);
}
