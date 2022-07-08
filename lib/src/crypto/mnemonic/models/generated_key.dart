import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/mnemonic/models/mnemonic_type.dart';

part 'generated_key.freezed.dart';
part 'generated_key.g.dart';

@freezed
class GeneratedKey with _$GeneratedKey {
  const factory GeneratedKey({
    required List<String> words,
    required MnemonicType accountType,
  }) = _GeneratedKey;

  factory GeneratedKey.fromJson(Map<String, dynamic> json) => _$GeneratedKeyFromJson(json);
}
