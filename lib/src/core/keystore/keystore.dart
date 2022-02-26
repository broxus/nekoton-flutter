import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../../bindings.dart';
import '../../crypto/models/create_key_input.dart';
import '../../crypto/models/derived_key_export_output.dart';
import '../../crypto/models/derived_key_export_params.dart';
import '../../crypto/models/encrypted_key_export_output.dart';
import '../../crypto/models/encrypted_key_password.dart';
import '../../crypto/models/export_key_input.dart';
import '../../crypto/models/export_key_output.dart';
import '../../crypto/models/sign_input.dart';
import '../../crypto/models/update_key_input.dart';
import '../../external/storage.dart';
import '../../ffi_utils.dart';
import '../../models/pointed.dart';
import 'models/key_store_entry.dart';

class Keystore implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;

  Keystore._();

  static Future<Keystore> create(Storage storage) async {
    final instance = Keystore._();
    await instance._initialize(storage);
    return instance;
  }

  Future<List<KeyStoreEntry>> get entries async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_entries(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final keys = list.map((e) => KeyStoreEntry.fromJson(e)).toList();

    return keys;
  }

  Future<KeyStoreEntry> addKey(CreateKeyInput createKeyInput) async {
    final ptr = await clonePtr();
    final createKeyInputStr = jsonEncode(createKeyInput);

    final result = await executeAsync(
      (port) => bindings().add_key(
        port,
        ptr,
        createKeyInputStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final key = KeyStoreEntry.fromJson(json);

    return key;
  }

  Future<KeyStoreEntry> updateKey(UpdateKeyInput updateKeyInput) async {
    final ptr = await clonePtr();
    final updateKeyInputStr = jsonEncode(updateKeyInput);

    final result = await executeAsync(
      (port) => bindings().update_key(
        port,
        ptr,
        updateKeyInputStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final key = KeyStoreEntry.fromJson(json);

    return key;
  }

  Future<ExportKeyOutput> exportKey(ExportKeyInput exportKeyInput) async {
    final ptr = await clonePtr();
    final exportKeyInputStr = jsonEncode(exportKeyInput);

    final result = await executeAsync(
      (port) => bindings().export_key(
        port,
        ptr,
        exportKeyInputStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;

    late ExportKeyOutput exportKeyOutput;

    if (exportKeyInput is EncryptedKeyPassword) {
      exportKeyOutput = EncryptedKeyExportOutput.fromJson(json);
    } else if (exportKeyInput is DerivedKeyExportParams) {
      exportKeyOutput = DerivedKeyExportOutput.fromJson(json);
    } else {
      throw Exception('Invalid signer');
    }

    return exportKeyOutput;
  }

  Future<bool> checkKeyPassword(SignInput signInput) async {
    final ptr = await clonePtr();
    final signInputStr = jsonEncode(signInput);

    final result = await executeAsync(
      (port) => bindings().check_key_password(
        port,
        ptr,
        signInputStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    final isValid = result == 1;

    return isValid;
  }

  Future<KeyStoreEntry?> removeKey(String publicKey) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().remove_key(
        port,
        ptr,
        publicKey.toNativeUtf8().cast<Int8>(),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>?;
    final key = json != null ? KeyStoreEntry.fromJson(json) : null;

    return key;
  }

  Future<void> clear() async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => bindings().clear_keystore(
        port,
        ptr,
      ),
    );
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Keystore use after free');

        final ptr = bindings().clone_keystore_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Keystore use after free');

        bindings().free_keystore_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _initialize(Storage storage) => _lock.synchronized(() async {
        final storagePtr = await storage.clonePtr();

        final result = await executeAsync(
          (port) => bindings().create_keystore(
            port,
            storagePtr,
          ),
        );

        _ptr = Pointer.fromAddress(result).cast<Void>();
      });
}
