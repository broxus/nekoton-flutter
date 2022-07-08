import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/models/encryption_algorithm.dart';

part 'encrypted_data.freezed.dart';
part 'encrypted_data.g.dart';

@freezed
class EncryptedData with _$EncryptedData {
  const factory EncryptedData({
    required EncryptionAlgorithm algorithm,
    required String sourcePublicKey,
    required String recipientPublicKey,
    required String data,
    required String nonce,
  }) = _EncryptedData;

  factory EncryptedData.fromJson(Map<String, dynamic> json) => _$EncryptedDataFromJson(json);
}
