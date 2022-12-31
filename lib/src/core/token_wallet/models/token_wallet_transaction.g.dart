// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_wallet_transaction.dart';

class TokenWalletTransactionIncomingTransferAdapter extends TypeAdapter<Object> {
  @override
  final int typeId = 15;

  @override
  Object read(BinaryReader reader) {
    return Object();
  }

  @override
  void write(BinaryWriter writer, Object obj) {}

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenWalletTransactionIncomingTransferAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TokenWalletTransactionOutgoingTransferAdapter extends TypeAdapter<Object> {
  @override
  final int typeId = 16;

  @override
  Object read(BinaryReader reader) {
    return Object();
  }

  @override
  void write(BinaryWriter writer, Object obj) {}

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenWalletTransactionOutgoingTransferAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TokenWalletTransactionSwapBackAdapter extends TypeAdapter<Object> {
  @override
  final int typeId = 17;

  @override
  Object read(BinaryReader reader) {
    return Object();
  }

  @override
  void write(BinaryWriter writer, Object obj) {}

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenWalletTransactionSwapBackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TokenWalletTransactionAcceptAdapter extends TypeAdapter<Object> {
  @override
  final int typeId = 18;

  @override
  Object read(BinaryReader reader) {
    return Object();
  }

  @override
  void write(BinaryWriter writer, Object obj) {}

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenWalletTransactionAcceptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TokenWalletTransactionTransferBouncedAdapter extends TypeAdapter<Object> {
  @override
  final int typeId = 19;

  @override
  Object read(BinaryReader reader) {
    return Object();
  }

  @override
  void write(BinaryWriter writer, Object obj) {}

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenWalletTransactionTransferBouncedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TokenWalletTransactionSwapBackBouncedAdapter extends TypeAdapter<Object> {
  @override
  final int typeId = 20;

  @override
  Object read(BinaryReader reader) {
    return Object();
  }

  @override
  void write(BinaryWriter writer, Object obj) {}

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenWalletTransactionSwapBackBouncedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_IncomingTransfer _$$_IncomingTransferFromJson(Map<String, dynamic> json) => _$_IncomingTransfer(
      TokenIncomingTransfer.fromJson(json['data'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$_IncomingTransferToJson(_$_IncomingTransfer instance) => <String, dynamic>{
      'data': instance.data.toJson(),
      'type': instance.$type,
    };

_$_OutgoingTransfer _$$_OutgoingTransferFromJson(Map<String, dynamic> json) => _$_OutgoingTransfer(
      TokenOutgoingTransfer.fromJson(json['data'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$_OutgoingTransferToJson(_$_OutgoingTransfer instance) => <String, dynamic>{
      'data': instance.data.toJson(),
      'type': instance.$type,
    };

_$_SwapBack _$$_SwapBackFromJson(Map<String, dynamic> json) => _$_SwapBack(
      TokenSwapBack.fromJson(json['data'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$_SwapBackToJson(_$_SwapBack instance) => <String, dynamic>{
      'data': instance.data.toJson(),
      'type': instance.$type,
    };

_$_Accept _$$_AcceptFromJson(Map<String, dynamic> json) => _$_Accept(
      json['data'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$_AcceptToJson(_$_Accept instance) => <String, dynamic>{
      'data': instance.data,
      'type': instance.$type,
    };

_$_TransferBounced _$$_TransferBouncedFromJson(Map<String, dynamic> json) => _$_TransferBounced(
      json['data'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$_TransferBouncedToJson(_$_TransferBounced instance) => <String, dynamic>{
      'data': instance.data,
      'type': instance.$type,
    };

_$_SwapBackBounced _$$_SwapBackBouncedFromJson(Map<String, dynamic> json) => _$_SwapBackBounced(
      json['data'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$_SwapBackBouncedToJson(_$_SwapBackBounced instance) => <String, dynamic>{
      'data': instance.data,
      'type': instance.$type,
    };
