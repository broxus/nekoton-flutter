// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_interaction_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

class WalletInteractionInfoAdapter extends TypeAdapter<_WalletInteractionInfo> {
  @override
  final int typeId = 48;

  @override
  _WalletInteractionInfo read(BinaryReader reader) {
    return const _WalletInteractionInfo(method: WalletInteractionMethod.walletV3Transfer());
  }

  @override
  void write(BinaryWriter writer, _WalletInteractionInfo obj) {}

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletInteractionInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_WalletInteractionInfo _$$_WalletInteractionInfoFromJson(Map<String, dynamic> json) =>
    _$_WalletInteractionInfo(
      recipient: json['recipient'] as String?,
      knownPayload: json['known_payload'] == null
          ? null
          : KnownPayload.fromJson(json['known_payload'] as Map<String, dynamic>),
      method: WalletInteractionMethod.fromJson(json['method'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_WalletInteractionInfoToJson(_$_WalletInteractionInfo instance) =>
    <String, dynamic>{
      'recipient': instance.recipient,
      'known_payload': instance.knownPayload?.toJson(),
      'method': instance.method.toJson(),
    };
