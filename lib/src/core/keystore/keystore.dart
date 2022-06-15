import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../../bindings.dart';
import '../../crypto/derived_key/constants.dart';
import '../../crypto/derived_key/derived_key_export_output.dart';
import '../../crypto/encrypted_key/constants.dart';
import '../../crypto/encrypted_key/encrypted_key_export_output.dart';
import '../../crypto/ledger_key/constants.dart';
import '../../crypto/models/create_key_input.dart';
import '../../crypto/models/encrypted_data.dart';
import '../../crypto/models/encryption_algorithm.dart';
import '../../crypto/models/export_key_input.dart';
import '../../crypto/models/export_key_output.dart';
import '../../crypto/models/get_public_keys.dart';
import '../../crypto/models/sign_input.dart';
import '../../crypto/models/signed_data.dart';
import '../../crypto/models/signed_data_raw.dart';
import '../../crypto/models/update_key_input.dart';
import '../../external/ledger_connection.dart';
import '../../external/storage.dart';
import '../../ffi_utils.dart';
import '../../models/pointed.dart';
import 'models/key_store_entry.dart';

class Keystore implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;

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

  Future<List<KeyStoreEntry>> get entries async {
    final ptr = await clonePtr();

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

  Future<KeyStoreEntry> addKey(CreateKeyInput input) async {
    final ptr = await clonePtr();
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

    final json = result as Map<String, dynamic>;
    final entry = KeyStoreEntry.fromJson(json);

    return entry;
  }

  Future<List<KeyStoreEntry>> addKeys(List<CreateKeyInput> input) async {
    final signers = input.map((e) => e.toSigner()).toSet().toList();

    assert(signers.length == 1);

    final ptr = await clonePtr();
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

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => KeyStoreEntry.fromJson(e)).toList();

    return entries;
  }

  Future<KeyStoreEntry> updateKey(UpdateKeyInput input) async {
    final ptr = await clonePtr();
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

    final json = result as Map<String, dynamic>;
    final entry = KeyStoreEntry.fromJson(json);

    return entry;
  }

  Future<ExportKeyOutput> exportKey(ExportKeyInput input) async {
    final ptr = await clonePtr();
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
      throw Exception('Invalid signer');
    }

    return output;
  }

  Future<List<String>> getPublicKeys(GetPublicKeys input) async {
    final ptr = await clonePtr();
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
    final ptr = await clonePtr();
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
    final ptr = await clonePtr();
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
  }) async {
    final ptr = await clonePtr();
    final signer = input.toSigner();
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_sign(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            data.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final signature = result as String;

    return signature;
  }

  Future<SignedData> signData({
    required String data,
    required SignInput input,
  }) async {
    final ptr = await clonePtr();
    final signer = input.toSigner();
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_sign_data(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            data.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;
    final signedData = SignedData.fromJson(json);

    return signedData;
  }

  Future<SignedDataRaw> signDataRaw({
    required String data,
    required SignInput input,
  }) async {
    final ptr = await clonePtr();
    final signer = input.toSigner();
    final inputStr = jsonEncode(input);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_sign_data_raw(
            port,
            ptr,
            signer.toNativeUtf8().cast<Char>(),
            data.toNativeUtf8().cast<Char>(),
            inputStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;
    final signedDataRaw = SignedDataRaw.fromJson(json);

    return signedDataRaw;
  }

  Future<KeyStoreEntry?> removeKey(String publicKey) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_remove_key(
            port,
            ptr,
            publicKey.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result != null ? result as Map<String, dynamic> : null;
    final entry = json != null ? KeyStoreEntry.fromJson(json) : null;

    return entry;
  }

  Future<List<KeyStoreEntry>> removeKeys(List<String> publicKeys) async {
    final ptr = await clonePtr();
    final publicKeysStr = jsonEncode(publicKeys);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_remove_keys(
            port,
            ptr,
            publicKeysStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => KeyStoreEntry.fromJson(e)).toList();

    return entries;
  }

  Future<bool> isPasswordCached({
    required String publicKey,
    required int duration,
  }) async {
    final ptr = await clonePtr();

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
    final ptr = await clonePtr();

    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_clear(
            port,
            ptr,
          ),
    );
  }

  Future<void> reload() async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_keystore_reload(
            port,
            ptr,
          ),
    );
  }

  static Future<bool> verify(
    LedgerConnection? ledgerConnection,
    List<String> signers,
    String data,
  ) async {
    assert(!signers.contains(kLedgerKeySignerName) || ledgerConnection != null);

    final ledgerConnectionPtr = await ledgerConnection?.clonePtr();
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

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Keystore use after free');

        final ptr = NekotonFlutter.instance().bindings.nt_keystore_clone_ptr(
              _ptr!,
            );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) return;

        NekotonFlutter.instance().bindings.nt_keystore_free_ptr(
              _ptr!,
            );

        _ptr = null;
      });

  Future<void> _initialize({
    required Storage storage,
    LedgerConnection? ledgerConnection,
    required List<String> signers,
  }) =>
      _lock.synchronized(() async {
        assert(!signers.contains(kLedgerKeySignerName) || ledgerConnection != null);

        final storagePtr = await storage.clonePtr();
        final ledgerConnectionPtr = await ledgerConnection?.clonePtr();
        final signersStr = jsonEncode(signers);

        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_keystore_create(
                port,
                storagePtr,
                ledgerConnectionPtr ?? nullptr,
                signersStr.toNativeUtf8().cast<Char>(),
              ),
        );

        _ptr = Pointer.fromAddress(result as int).cast<Void>();
      });
}
