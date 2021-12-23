import 'package:freezed_annotation/freezed_annotation.dart';

import 'derived_key_export_output.dart';
import 'encrypted_key_export_output.dart';

part 'export_key_output.freezed.dart';

@freezed
class ExportKeyOutput with _$ExportKeyOutput {
  const factory ExportKeyOutput.derivedKeyExportOutput(
    DerivedKeyExportOutput derivedKeyExportOutput,
  ) = _DerivedKeyExportOutput;

  const factory ExportKeyOutput.encryptedKeyExportOutput(
    EncryptedKeyExportOutput encryptedKeyExportOutput,
  ) = _EncryptedKeyExportOutput;
}
