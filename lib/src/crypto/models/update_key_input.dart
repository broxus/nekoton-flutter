import '../derived_key/constants.dart';
import '../derived_key/derived_key_update_params.dart';
import '../encrypted_key/constants.dart';
import '../encrypted_key/encrypted_key_update_params.dart';
import '../ledger_key/constants.dart';
import '../ledger_key/ledger_update_key_input.dart';

abstract class UpdateKeyInput {
  Map<String, dynamic> toJson();
}

extension UpdateKeyInputToSigner on UpdateKeyInput {
  String toSigner() {
    if (this is EncryptedKeyUpdateParams) return kEncryptedKeySignerName;
    if (this is DerivedKeyUpdateParams) return kDerivedKeySignerName;
    if (this is LedgerUpdateKeyInput) return kLedgerKeySignerName;
    throw Exception('Invalid signer');
  }
}
