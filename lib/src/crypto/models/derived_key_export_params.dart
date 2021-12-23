import 'package:freezed_annotation/freezed_annotation.dart';

import 'password.dart';

part 'derived_key_export_params.freezed.dart';
part 'derived_key_export_params.g.dart';

@freezed
class DerivedKeyExportParams with _$DerivedKeyExportParams {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory DerivedKeyExportParams({
    required String masterKey,
    required Password password,
  }) = _DerivedKeyExportParams;

  factory DerivedKeyExportParams.fromJson(Map<String, dynamic> json) => _$DerivedKeyExportParamsFromJson(json);
}
