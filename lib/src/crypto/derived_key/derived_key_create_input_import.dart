import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/password_cache/password.dart';

part 'derived_key_create_input_import.freezed.dart';
part 'derived_key_create_input_import.g.dart';

@freezed
class DerivedKeyCreateInputImport with _$DerivedKeyCreateInputImport {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DerivedKeyCreateInputImport({
    String? keyName,
    required String phrase,
    required Password password,
  }) = _DerivedKeyCreateInputImportImport;

  factory DerivedKeyCreateInputImport.fromJson(Map<String, dynamic> json) =>
      _$DerivedKeyCreateInputImportFromJson(json);
}
