import 'package:freezed_annotation/freezed_annotation.dart';

part 'encryption_algorithm.g.dart';

@JsonEnum(
  alwaysCreate: true,
  fieldRename: FieldRename.pascal,
)
enum EncryptionAlgorithm {
  chaCha20Poly1305;

  @override
  String toString() => _$EncryptionAlgorithmEnumMap[this]!;
}
