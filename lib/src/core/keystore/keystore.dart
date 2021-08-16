import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';

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
import '../../models/nekoton_exception.dart';
import '../../native_library.dart';
import 'models/key_store_entry.dart';
import 'models/native_keystore.dart';

class Keystore {
  static Keystore? _instance;
  final _nativeLibrary = NativeLibrary.instance();
  final Logger? _logger;
  late final Storage _storage;
  late final NativeKeystore nativeKeystore;

  Keystore._(this._logger);

  static Future<Keystore> getInstance({
    Logger? logger,
  }) async {
    if (_instance == null) {
      final instance = Keystore._(logger);
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Future<List<KeyStoreEntry>> get entries async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_entries(
          port,
          nativeKeystore.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final jsonList = json.cast<Map<String, dynamic>>();
    final list = jsonList.map((e) => KeyStoreEntry.fromJson(e)).toList();

    return list;
  }

  Future<KeyStoreEntry> addKey(CreateKeyInput createKeyInput) async {
    final createKeyInputStr = jsonEncode(createKeyInput.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.add_key(
          port,
          nativeKeystore.ptr!,
          createKeyInputStr.toNativeUtf8().cast<Int8>(),
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final entry = KeyStoreEntry.fromJson(json);

    return entry;
  }

  Future<KeyStoreEntry> updateKey(UpdateKeyInput updateKeyInput) async {
    final updateKeyInputStr = jsonEncode(updateKeyInput.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.update_key(
          port,
          nativeKeystore.ptr!,
          updateKeyInputStr.toNativeUtf8().cast<Int8>(),
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final entry = KeyStoreEntry.fromJson(json);

    return entry;
  }

  Future<ExportKeyOutput> exportKey(ExportKeyInput exportKeyInput) async {
    final exportKeyInputStr = jsonEncode(exportKeyInput.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.export_key(
          port,
          nativeKeystore.ptr!,
          exportKeyInputStr.toNativeUtf8().cast<Int8>(),
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;

    if (exportKeyInput is DerivedKeyExportParams) {
      return DerivedKeyExportOutput.fromJson(json);
    } else if (exportKeyInput is EncryptedKeyPassword) {
      return EncryptedKeyExportOutput.fromJson(json);
    } else {
      throw UnknownSignerException();
    }
  }

  Future<bool> checkKeyPassword(SignInput signInput) async {
    final signInputStr = jsonEncode(signInput.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.check_key_password(
          port,
          nativeKeystore.ptr!,
          signInputStr.toNativeUtf8().cast<Int8>(),
        ));

    return result == 1;
  }

  Future<KeyStoreEntry?> removeKey(String publicKey) async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.remove_key(
          port,
          nativeKeystore.ptr!,
          publicKey.toNativeUtf8().cast<Int8>(),
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>?;
    final entry = json != null ? KeyStoreEntry.fromJson(json) : null;

    return entry;
  }

  Future<void> clear() async => proceedAsync((port) => _nativeLibrary.bindings.clear_keystore(
        port,
        nativeKeystore.ptr!,
      ));

  Future<void> _initialize() async {
    _storage = await Storage.getInstance(logger: _logger);

    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_keystore(
          port,
          _storage.nativeStorage.ptr!,
        ));
    final ptr = Pointer.fromAddress(result).cast<Void>();

    nativeKeystore = NativeKeystore(ptr);
  }

  @override
  String toString() => 'Keystore(${nativeKeystore.ptr?.address})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || other is Keystore && other.nativeKeystore.ptr?.address == nativeKeystore.ptr?.address;

  @override
  int get hashCode => nativeKeystore.ptr?.address ?? 0;
}
