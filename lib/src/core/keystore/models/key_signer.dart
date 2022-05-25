import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum(fieldRename: FieldRename.pascal)
enum KeySigner {
  encryptedKeySigner,
  derivedKeySigner,
}
