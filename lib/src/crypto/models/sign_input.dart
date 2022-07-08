import 'package:nekoton_flutter/src/crypto/derived_key/constants.dart';
import 'package:nekoton_flutter/src/crypto/derived_key/derived_key_sign_params.dart';
import 'package:nekoton_flutter/src/crypto/encrypted_key/constants.dart';
import 'package:nekoton_flutter/src/crypto/encrypted_key/encrypted_key_password.dart';
import 'package:nekoton_flutter/src/crypto/ledger_key/constants.dart';
import 'package:nekoton_flutter/src/crypto/ledger_key/ledger_sign_input.dart';

abstract class SignInput {
  Map<String, dynamic> toJson();
}

extension SignInputToSigner on SignInput {
  String toSigner() {
    if (this is EncryptedKeyPassword) return kEncryptedKeySignerName;
    if (this is DerivedKeySignParams) return kDerivedKeySignerName;
    if (this is LedgerSignInput) return kLedgerKeySignerName;
    throw UnsupportedError('Invalid signer');
  }
}
