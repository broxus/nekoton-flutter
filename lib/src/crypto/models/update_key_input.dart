import 'package:nekoton_flutter/src/crypto/derived_key/constants.dart';
import 'package:nekoton_flutter/src/crypto/derived_key/derived_key_update_params.dart';
import 'package:nekoton_flutter/src/crypto/encrypted_key/constants.dart';
import 'package:nekoton_flutter/src/crypto/encrypted_key/encrypted_key_update_params.dart';
import 'package:nekoton_flutter/src/crypto/ledger_key/constants.dart';
import 'package:nekoton_flutter/src/crypto/ledger_key/ledger_update_key_input.dart';

abstract class UpdateKeyInput {
  Map<String, dynamic> toJson();
}

extension UpdateKeyInputToSigner on UpdateKeyInput {
  String toSigner() {
    if (this is EncryptedKeyUpdateParams) return kEncryptedKeySignerName;
    if (this is DerivedKeyUpdateParams) return kDerivedKeySignerName;
    if (this is LedgerUpdateKeyInput) return kLedgerKeySignerName;
    throw UnsupportedError('Invalid signer');
  }
}
