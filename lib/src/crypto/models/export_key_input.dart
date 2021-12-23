import 'package:freezed_annotation/freezed_annotation.dart';

import 'derived_key_export_params.dart';
import 'encrypted_key_password.dart';

part 'export_key_input.freezed.dart';

@freezed
class ExportKeyInput with _$ExportKeyInput {
  const factory ExportKeyInput.derivedKeyExportParams(
    DerivedKeyExportParams derivedKeyExportParams,
  ) = _DerivedKeyExportParams;

  const factory ExportKeyInput.encryptedKeyPassword(
    EncryptedKeyPassword encryptedKeyPassword,
  ) = _EncryptedKeyPassword;
}
