import '../derived_key/constants.dart';
import '../derived_key/derived_key_get_public_keys.dart';
import '../encrypted_key/constants.dart';
import '../encrypted_key/encrypted_key_get_public_keys.dart';
import '../ledger_key/constants.dart';
import '../ledger_key/ledger_key_get_public_keys.dart';

abstract class GetPublicKeys {
  Map<String, dynamic> toJson();
}

extension GetPublicKeysToSigner on GetPublicKeys {
  String toSigner() {
    if (this is EncryptedKeyGetPublicKeys) return kEncryptedKeySignerName;
    if (this is DerivedKeyGetPublicKeys) return kDerivedKeySignerName;
    if (this is LedgerKeyGetPublicKeys) return kLedgerKeySignerName;
    throw Exception('Invalid signer');
  }
}
