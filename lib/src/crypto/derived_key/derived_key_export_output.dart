import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/models/export_key_output.dart';

part 'derived_key_export_output.freezed.dart';
part 'derived_key_export_output.g.dart';

@freezed
abstract class DerivedKeyExportOutput
    with _$DerivedKeyExportOutput
    implements ExportKeyOutput {
  const factory DerivedKeyExportOutput({
    required String phrase,
  }) = _DerivedKeyExportOutput;

  factory DerivedKeyExportOutput.fromJson(Map<String, dynamic> json) =>
      _$DerivedKeyExportOutputFromJson(json);
}
