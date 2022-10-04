import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/derived_key/constants.dart';
import 'package:nekoton_flutter/src/crypto/encrypted_key/constants.dart';
import 'package:nekoton_flutter/src/crypto/ledger_key/constants.dart';

part 'key_store_entry.freezed.dart';
part 'key_store_entry.g.dart';

@freezed
class KeyStoreEntry with _$KeyStoreEntry implements Comparable<KeyStoreEntry> {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory KeyStoreEntry({
    required String signerName,
    required String name,
    required String publicKey,
    required String masterKey,
    required int accountId,
  }) = _KeyStoreEntry;

  factory KeyStoreEntry.fromJson(Map<String, dynamic> json) => _$KeyStoreEntryFromJson(json);

  const KeyStoreEntry._();

  bool get isLegacy => signerName == kEncryptedKeySignerName;

  bool get isNotLegacy => signerName == kDerivedKeySignerName || signerName == kLedgerKeySignerName;

  bool get isMaster => publicKey == masterKey;

  @override
  int compareTo(KeyStoreEntry other) => publicKey.compareTo(other.publicKey);
}
