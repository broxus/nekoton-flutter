import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'key_signer.dart';

part 'key_store_entry.freezed.dart';
part 'key_store_entry.g.dart';

@freezed
class KeyStoreEntry with _$KeyStoreEntry implements Comparable<KeyStoreEntry> {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory KeyStoreEntry({
    required KeySigner signerName,
    required String name,
    required String publicKey,
    required String masterKey,
    required int accountId,
  }) = _KeyStoreEntry;

  factory KeyStoreEntry.fromJson(Map<String, dynamic> json) => _$KeyStoreEntryFromJson(json);

  const KeyStoreEntry._();

  bool get isLegacy => signerName == KeySigner.encryptedKeySigner;

  bool get isNotLegacy => signerName == KeySigner.derivedKeySigner;

  bool get isMaster => publicKey == masterKey;

  @override
  int compareTo(KeyStoreEntry other) => publicKey.compareTo(other.publicKey);
}
