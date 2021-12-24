import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';

import '../../crypto/models/create_key_input.dart';
import '../../crypto/models/derived_key_export_output.dart';
import '../../crypto/models/derived_key_sign_params.dart';
import '../../crypto/models/encrypted_key_export_output.dart';
import '../../crypto/models/encrypted_key_password.dart';
import '../../crypto/models/export_key_input.dart';
import '../../crypto/models/export_key_output.dart';
import '../../crypto/models/password.dart';
import '../../crypto/models/password_cache_behavior.dart';
import '../../crypto/models/sign_input.dart';
import '../../crypto/models/update_key_input.dart';
import '../../external/storage.dart';
import '../../ffi_utils.dart';
import '../../models/nekoton_exception.dart';
import '../../nekoton.dart';
import 'models/key_store_entry.dart';
import 'models/native_keystore.dart';

class Keystore {
  static Keystore? _instance;
  late final Storage _storage;
  late final NativeKeystore nativeKeystore;

  Keystore._();

  static Future<Keystore> getInstance() async {
    if (_instance == null) {
      final instance = Keystore._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Future<List<KeyStoreEntry>> get entries async {
    final result = await nativeKeystore.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_entries(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final keys = list.map((e) => KeyStoreEntry.fromJson(e)).toList();

    return keys;
  }

  Future<KeyStoreEntry> addKey(CreateKeyInput createKeyInput) async {
    final createKeyInputStr = createKeyInput.when(
      derivedKeyCreateInput: (derivedKeyCreateInput) => jsonEncode(derivedKeyCreateInput),
      encryptedKeyCreateInput: (encryptedKeyCreateInput) => jsonEncode(encryptedKeyCreateInput),
    );

    final result = await nativeKeystore.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.add_key(
          port,
          ptr,
          createKeyInputStr.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final key = KeyStoreEntry.fromJson(json);

    return key;
  }

  Future<KeyStoreEntry> updateKey(UpdateKeyInput updateKeyInput) async {
    final updateKeyInputStr = updateKeyInput.when(
      derivedKeyUpdateParams: (derivedKeyUpdateParams) => jsonEncode(derivedKeyUpdateParams),
      encryptedKeyUpdateParams: (encryptedKeyUpdateParams) => jsonEncode(encryptedKeyUpdateParams),
    );

    final result = await nativeKeystore.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.update_key(
          port,
          ptr,
          updateKeyInputStr.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final key = KeyStoreEntry.fromJson(json);

    return key;
  }

  Future<ExportKeyOutput> exportKey(ExportKeyInput exportKeyInput) async {
    final exportKeyInputStr = exportKeyInput.when(
      derivedKeyExportParams: (derivedKeyExportParams) => jsonEncode(derivedKeyExportParams),
      encryptedKeyPassword: (encryptedKeyPassword) => jsonEncode(encryptedKeyPassword),
    );

    final result = await nativeKeystore.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.export_key(
          port,
          ptr,
          exportKeyInputStr.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;

    return exportKeyInput.when(
      derivedKeyExportParams: (_) => ExportKeyOutput.derivedKeyExportOutput(
        DerivedKeyExportOutput.fromJson(json),
      ),
      encryptedKeyPassword: (_) => ExportKeyOutput.encryptedKeyExportOutput(
        EncryptedKeyExportOutput.fromJson(json),
      ),
    );
  }

  Future<bool> checkKeyPassword(SignInput signInput) async {
    final signInputStr = signInput.when(
      derivedKeySignParams: (derivedKeySignParams) => jsonEncode(derivedKeySignParams),
      encryptedKeyPassword: (encryptedKeyPassword) => jsonEncode(encryptedKeyPassword),
    );

    final result = await nativeKeystore.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.check_key_password(
          port,
          ptr,
          signInputStr.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );

    return result == 1;
  }

  Future<SignInput> getSignInput({
    required String publicKey,
    required String password,
  }) async {
    final key = await entries.then((e) => e.firstWhereOrNull((e) => e.publicKey == publicKey));

    if (key == null) {
      throw KeyNotFoundException();
    }

    return key.isLegacy
        ? SignInput.encryptedKeyPassword(
            EncryptedKeyPassword(
              publicKey: key.publicKey,
              password: Password.explicit(
                password: password,
                cacheBehavior: const PasswordCacheBehavior.remove(),
              ),
            ),
          )
        : SignInput.derivedKeySignParams(
            DerivedKeySignParams.byAccountId(
              masterKey: key.masterKey,
              accountId: key.accountId,
              password: Password.explicit(
                password: password,
                cacheBehavior: const PasswordCacheBehavior.remove(),
              ),
            ),
          );
  }

  Future<KeyStoreEntry?> removeKey(String publicKey) async {
    final result = await nativeKeystore.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.remove_key(
          port,
          ptr,
          publicKey.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>?;
    final key = json != null ? KeyStoreEntry.fromJson(json) : null;

    return key;
  }

  Future<void> clear() => nativeKeystore.use(
        (ptr) => proceedAsync(
          (port) => nativeLibraryInstance.bindings.clear_keystore(
            port,
            ptr,
          ),
        ),
      );

  Future<void> free() => nativeKeystore.free();

  Future<void> _initialize() async {
    _storage = await Storage.getInstance();

    final result = await _storage.nativeStorage.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_keystore(
          port,
          ptr,
        ),
      ),
    );
    final ptr = Pointer.fromAddress(result).cast<Void>();

    nativeKeystore = NativeKeystore(ptr);
  }
}
