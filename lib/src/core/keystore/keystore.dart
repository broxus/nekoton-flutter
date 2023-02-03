import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/keystore/models/key_store_entry.dart';
import 'package:nekoton_flutter/src/core/utils.dart';
import 'package:nekoton_flutter/src/crypto/derived_key/constants.dart';
import 'package:nekoton_flutter/src/crypto/derived_key/derived_key_export_output.dart';
import 'package:nekoton_flutter/src/crypto/encrypted_key/constants.dart';
import 'package:nekoton_flutter/src/crypto/encrypted_key/encrypted_key_export_output.dart';
import 'package:nekoton_flutter/src/crypto/ledger_key/constants.dart';
import 'package:nekoton_flutter/src/crypto/models/create_key_input.dart';
import 'package:nekoton_flutter/src/crypto/models/encrypted_data.dart';
import 'package:nekoton_flutter/src/crypto/models/encryption_algorithm.dart';
import 'package:nekoton_flutter/src/crypto/models/export_key_input.dart';
import 'package:nekoton_flutter/src/crypto/models/export_key_output.dart';
import 'package:nekoton_flutter/src/crypto/models/get_public_keys.dart';
import 'package:nekoton_flutter/src/crypto/models/sign_input.dart';
import 'package:nekoton_flutter/src/crypto/models/signed_data.dart';
import 'package:nekoton_flutter/src/crypto/models/signed_data_raw.dart';
import 'package:nekoton_flutter/src/crypto/models/update_key_input.dart';
import 'package:nekoton_flutter/src/external/ledger_connection.dart';
import 'package:nekoton_flutter/src/external/storage.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:rxdart/rxdart.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_keystore_free_ptr);

class Keystore implements Finalizable {
  late final Pointer<Void> _ptr;
  final _entriesSubject = BehaviorSubject<List<KeyStoreEntry>>();

  Keystore._();

  static Future<Keystore> create({
    required Storage storage,
    LedgerConnection? ledgerConnection,
    required List<String> signers,
  }) async {
    final instance = Keystore._();
    await instance._initialize(
      storage: storage,
      ledgerConnection: ledgerConnection,
      signers: signers,
    );
    return instance;
  }

  Pointer<Void> get ptr => _ptr;

  Stream<List<KeyStoreEntry>> get entriesStream =>
      _entriesSubject.distinct((a, b) => listEquals(a, b));

  List<KeyStoreEntry> get entries => _entriesSubject.value;

  Future<List<KeyStoreEntry>> get _entries async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_entries(
            port,
            ptr,
          ),
    );

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => KeyStoreEntry.fromJson(e)).toList();

    return entries;
  }

  static bool verify({
    LedgerConnection? ledgerConnection,
    required List<String> signers,
    required String data,
  }) {
    assert(!signers.contains(kLedgerKeySignerName) || ledgerConnection != null);

    final ledgerConnectionPtr = ledgerConnection?.ptr;
    final signersStr = jsonEncode(signers);

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_keystore_verify_data(
            ledgerConnectionPtr ?? nullptr,
            signersStr.toNativeUtf8().cast<Char>(),
            data.toNativeUtf8().cast<Char>(),
          ),
    );

    final isValid = result != 0;

    return isValid;
  }

  Future<KeyStoreEntry> addKey(CreateKeyInput input) async {
    final signer = input.toSigner();
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_add_key(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as Map<String, dynamic>;
    final entry = KeyStoreEntry.fromJson(json);

    return entry;
  }

  Future<List<KeyStoreEntry>> addKeys(List<CreateKeyInput> input) async {
    final signers = input.map((e) => e.toSigner()).toSet().toList();

    assert(signers.length == 1);

    final signer = signers.first;
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_add_key(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => KeyStoreEntry.fromJson(e)).toList();

    return entries;
  }

  Future<KeyStoreEntry> updateKey(UpdateKeyInput input) async {
    final signer = input.toSigner();
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_update_key(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as Map<String, dynamic>;
    final entry = KeyStoreEntry.fromJson(json);

    return entry;
  }

  Future<ExportKeyOutput> exportKey(ExportKeyInput input) async {
    final signer = input.toSigner();
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_export_key(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;

    ExportKeyOutput output;

    if (signer == kEncryptedKeySignerName) {
      output = EncryptedKeyExportOutput.fromJson(json);
    } else if (signer == kDerivedKeySignerName) {
      output = DerivedKeyExportOutput.fromJson(json);
    } else {
      throw UnsupportedError('Invalid signer');
    }

    return output;
  }

  Future<List<String>> getPublicKeys(GetPublicKeys input) async {
    final signer = input.toSigner();
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_get_public_keys(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as List<dynamic>;
    final publicKeys = json.cast<String>();

    return publicKeys;
  }

  Future<List<EncryptedData>> encrypt({
    required String data,
    required List<String> publicKeys,
    required EncryptionAlgorithm algorithm,
    required SignInput input,
  }) async {
    final signer = input.toSigner();
    final publicKeysStr = jsonEncode(publicKeys);
    final algorithmStr = algorithm.toString();
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_encrypt(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            data.toNativeUtf8().cast<Char>(),
            publicKeysStr.toNativeUtf8().cast<Char>(),
            algorithmStr.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final encryptedData = list.map((e) => EncryptedData.fromJson(e)).toList();

    return encryptedData;
  }

  Future<String> decrypt({
    required EncryptedData data,
    required SignInput input,
  }) async {
    final signer = input.toSigner();
    final dataStr = jsonEncode(data);
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_decrypt(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            dataStr.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final decryptedData = result as String;

    return decryptedData;
  }

  Future<String> sign({
    required String data,
    required SignInput input,
    required String? signatureId,
  }) async {
    final signer = input.toSigner();
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_sign(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            data.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
            signatureId?.toNativeUtf8().cast<Char>() ?? nullptr,
          ),
    );

    final signature = result as String;

    return signature;
  }

  Future<SignedData> signData({
    required String data,
    required SignInput input,
    required String? signatureId,
  }) async {
    final signer = input.toSigner();
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_sign_data(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            data.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
            signatureId?.toNativeUtf8().cast<Char>() ?? nullptr,
          ),
    );

    final json = result as Map<String, dynamic>;
    final signedData = SignedData.fromJson(json);

    return signedData;
  }

  Future<SignedDataRaw> signDataRaw({
    required String data,
    required SignInput input,
    required String? signatureId,
  }) async {
    final signer = input.toSigner();
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_sign_data_raw(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            data.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
            signatureId?.toNativeUtf8().cast<Char>() ?? nullptr,
          ),
    );

    final json = result as Map<String, dynamic>;
    final signedData = SignedDataRaw.fromJson(json);

    return signedData;
  }

  Future<KeyStoreEntry?> removeKey(String publicKey) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_remove_key(
            port,
            ptr,
            publicKey.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as Map<String, dynamic>?;
    final entry = json != null ? KeyStoreEntry.fromJson(json) : null;

    return entry;
  }

  Future<List<KeyStoreEntry>> removeKeys(List<String> publicKeys) async {
    final publicKeysStr = jsonEncode(publicKeys);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_remove_keys(
            port,
            ptr,
            publicKeysStr.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => KeyStoreEntry.fromJson(e)).toList();

    return entries;
  }

  Future<bool> isPasswordCached({
    required String publicKey,
    required int duration,
  }) async {
    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_keystore_is_password_cached(
            ptr,
            publicKey.toNativeUtf8().cast<Char>(),
            duration,
          ),
    );

    final isCached = result != 0;

    return isCached;
  }

  Future<void> clear() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_clear(
            port,
            ptr,
          ),
    );

    await _updateData();
  }

  Future<void> reload() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_reload(
            port,
            ptr,
          ),
    );

    await _updateData();
  }

  Future<void> dispose() => _entriesSubject.close();

  Future<void> _updateData() async => _entriesSubject.tryAdd(await _entries);

  Future<void> _initialize({
    required Storage storage,
    LedgerConnection? ledgerConnection,
    required List<String> signers,
  }) async {
    assert(!signers.contains(kLedgerKeySignerName) || ledgerConnection != null);

    final storagePtr = storage.ptr;
    final ledgerConnectionPtr = ledgerConnection?.ptr;
    final signersStr = jsonEncode(signers);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_create(
            port,
            storagePtr,
            ledgerConnectionPtr ?? nullptr,
            signersStr.toNativeUtf8().cast<Char>(),
          ),
    );

    _ptr = toPtrFromAddress(result as String);

    _nativeFinalizer.attach(this, _ptr);

    await _updateData();
  }
}
