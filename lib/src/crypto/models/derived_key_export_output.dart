import 'package:freezed_annotation/freezed_annotation.dart';

part 'derived_key_export_output.freezed.dart';
part 'derived_key_export_output.g.dart';

@freezed
class DerivedKeyExportOutput with _$DerivedKeyExportOutput {
  const factory DerivedKeyExportOutput({
    required String phrase,
  }) = _DerivedKeyExportOutput;

  factory DerivedKeyExportOutput.fromJson(Map<String, dynamic> json) => _$DerivedKeyExportOutputFromJson(json);
}
