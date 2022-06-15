import '../derived_key/constants.dart';
import '../derived_key/derived_key_create_input.dart';
import '../encrypted_key/constants.dart';
import '../encrypted_key/encrypted_key_create_input.dart';
import '../ledger_key/constants.dart';
import '../ledger_key/ledger_key_create_input.dart';

abstract class CreateKeyInput {
  Map<String, dynamic> toJson();
}

extension CreateKeyInputToSigner on CreateKeyInput {
  String toSigner() {
    if (this is EncryptedKeyCreateInput) return kEncryptedKeySignerName;
    if (this is DerivedKeyCreateInput) return kDerivedKeySignerName;
    if (this is LedgerKeyCreateInput) return kLedgerKeySignerName;
    throw Exception();
  }
}
