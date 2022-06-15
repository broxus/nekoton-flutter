import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/create_key_input.dart';
import 'derived_key_create_input_derive.dart';
import 'derived_key_create_input_import.dart';

part 'derived_key_create_input.freezed.dart';
part 'derived_key_create_input.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class DerivedKeyCreateInput with _$DerivedKeyCreateInput implements CreateKeyInput {
  const factory DerivedKeyCreateInput.import(DerivedKeyCreateInputImport data) = _DerivedKeyCreateInputImport;

  const factory DerivedKeyCreateInput.derive(DerivedKeyCreateInputDerive data) = _DerivedKeyCreateInputDerive;

  factory DerivedKeyCreateInput.fromJson(Map<String, dynamic> json) => _$DerivedKeyCreateInputFromJson(json);
}
