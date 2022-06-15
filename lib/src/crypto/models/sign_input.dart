import '../derived_key/constants.dart';
import '../derived_key/derived_key_sign_params.dart';
import '../encrypted_key/constants.dart';
import '../encrypted_key/encrypted_key_password.dart';
import '../ledger_key/constants.dart';
import '../ledger_key/ledger_sign_input.dart';

abstract class SignInput {
  Map<String, dynamic> toJson();
}

extension SignInputToSigner on SignInput {
  String toSigner() {
    if (this is EncryptedKeyPassword) return kEncryptedKeySignerName;
    if (this is DerivedKeySignParams) return kDerivedKeySignerName;
    if (this is LedgerSignInput) return kLedgerKeySignerName;
    throw Exception();
  }
}
