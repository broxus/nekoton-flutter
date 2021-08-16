import 'package:freezed_annotation/freezed_annotation.dart';

enum KeySigner {
  @JsonValue('EncryptedKeySigner')
  encryptedKeySigner,
  @JsonValue('DerivedKeySigner')
  derivedKeySigner,
}
