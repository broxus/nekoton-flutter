import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/derived_key/derived_key_create_input_derive.dart';
import 'package:nekoton_flutter/src/crypto/derived_key/derived_key_create_input_import.dart';
import 'package:nekoton_flutter/src/crypto/models/create_key_input.dart';

part 'derived_key_create_input.freezed.dart';
part 'derived_key_create_input.g.dart';

@Freezed(unionKey: 'type')
class DerivedKeyCreateInput with _$DerivedKeyCreateInput implements CreateKeyInput {
  const factory DerivedKeyCreateInput.import(DerivedKeyCreateInputImport data) = _Import;

  const factory DerivedKeyCreateInput.derive(DerivedKeyCreateInputDerive data) = _Derive;

  factory DerivedKeyCreateInput.fromJson(Map<String, dynamic> json) =>
      _$DerivedKeyCreateInputFromJson(json);
}
