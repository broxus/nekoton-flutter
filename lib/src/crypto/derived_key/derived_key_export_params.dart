import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/models/export_key_input.dart';
import 'package:nekoton_flutter/src/crypto/password_cache/password.dart';

part 'derived_key_export_params.freezed.dart';
part 'derived_key_export_params.g.dart';

@freezed
class DerivedKeyExportParams with _$DerivedKeyExportParams implements ExportKeyInput {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DerivedKeyExportParams({
    required String masterKey,
    required Password password,
  }) = _DerivedKeyExportParams;

  factory DerivedKeyExportParams.fromJson(Map<String, dynamic> json) =>
      _$DerivedKeyExportParamsFromJson(json);
}
