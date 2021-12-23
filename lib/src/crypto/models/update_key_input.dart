import 'package:freezed_annotation/freezed_annotation.dart';

import 'derived_key_update_params.dart';
import 'encrypted_key_update_params.dart';

part 'update_key_input.freezed.dart';

@freezed
class UpdateKeyInput with _$UpdateKeyInput {
  const factory UpdateKeyInput.derivedKeyUpdateParams(
    DerivedKeyUpdateParams derivedKeyUpdateParams,
  ) = _DerivedKeyUpdateParams;

  const factory UpdateKeyInput.encryptedKeyUpdateParams(
    EncryptedKeyUpdateParams encryptedKeyUpdateParams,
  ) = _EncryptedKeyUpdateParams;
}
