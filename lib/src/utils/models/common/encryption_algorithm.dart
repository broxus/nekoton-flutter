import 'package:freezed_annotation/freezed_annotation.dart';

enum EncryptionAlgorithm {
  @JsonValue('ChaCha20Poly1305')
  chaCha20Poly1305,
}
