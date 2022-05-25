import 'package:freezed_annotation/freezed_annotation.dart';

part 'encryption_algorithm.g.dart';

@JsonEnum(
  alwaysCreate: true,
  fieldRename: FieldRename.pascal,
)
enum EncryptionAlgorithm {
  chaCha20Poly1305,
}

extension EnumString on EncryptionAlgorithm {
  String toEnumString() => _$EncryptionAlgorithmEnumMap[this]!;
}
