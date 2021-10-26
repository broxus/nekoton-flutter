import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import 'core/keystore/keystore.dart';
import 'core/keystore/models/key_store_entry.dart';
import 'crypto/models/create_key_input.dart';
import 'crypto/models/export_key_input.dart';
import 'crypto/models/export_key_output.dart';
import 'crypto/models/sign_input.dart';
import 'crypto/models/update_key_input.dart';
import 'preferences.dart';
import 'provider/provider_events.dart';

class KeystoreController {
  static KeystoreController? _instance;
  late final Keystore _keystore;
  late final Preferences _preferences;
  final _keysSubject = BehaviorSubject<List<KeyStoreEntry>>.seeded([]);
  final _currentKeySubject = BehaviorSubject<KeyStoreEntry?>.seeded(null);

  KeystoreController._();

  static Future<KeystoreController> getInstance() async {
    if (_instance == null) {
      final instance = KeystoreController._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Stream<List<KeyStoreEntry>> get keysStream => _keysSubject.stream.distinct();

  List<KeyStoreEntry> get keys => _keysSubject.value;

  Stream<KeyStoreEntry?> get currentKeyStream => _currentKeySubject.stream.distinct();

  KeyStoreEntry? get currentKey => _currentKeySubject.value;

  set currentKey(KeyStoreEntry? currentKey) {
    _currentKeySubject.add(currentKey);
    _preferences.setCurrentPublicKey(currentKey?.publicKey);
  }

  Future<KeyStoreEntry> addKey(CreateKeyInput createKeyInput) async {
    final key = await _keystore.addKey(createKeyInput);

    final keys = [..._keysSubject.value];

    keys
      ..removeWhere((e) => e.publicKey == key.publicKey)
      ..add(key)
      ..sort();

    _keysSubject.add(keys);

    currentKey ??= _keysSubject.value.firstOrNull;

    return key;
  }

  Future<KeyStoreEntry> updateKey(UpdateKeyInput updateKeyInput) async {
    final keys = [..._keysSubject.value];

    final key = await _keystore.updateKey(updateKeyInput);

    keys
      ..removeWhere((e) => e.publicKey == key.publicKey)
      ..add(key)
      ..sort();

    _keysSubject.add(keys);

    return key;
  }

  Future<ExportKeyOutput> exportKey(ExportKeyInput exportKeyInput) async => _keystore.exportKey(exportKeyInput);

  Future<bool> checkKeyPassword(SignInput signInput) async => _keystore.checkKeyPassword(signInput);

  Future<KeyStoreEntry?> removeKey(String publicKey) async {
    final key = _keysSubject.value.firstWhereOrNull((e) => e.publicKey == publicKey);

    if (key == null) {
      return null;
    }

    if (currentKey == key) {
      final newCurrentKey = _keysSubject.value.firstWhereOrNull((e) => e != key);
      currentKey = newCurrentKey;
    }

    final keys = [..._keysSubject.value];

    keys
      ..remove(key)
      ..sort();

    _keysSubject.add(keys);

    await _keystore.removeKey(key.publicKey);

    final derivedKeys = _keysSubject.value.where((e) => e.masterKey == key.publicKey);

    for (final key in derivedKeys) {
      await removeKey(key.publicKey);
    }

    return key;
  }

  Future<void> clearKeystore() async {
    currentKey = null;

    _keysSubject.add([]);

    await _keystore.clear();
  }

  Future<void> _initialize() async {
    _keystore = await Keystore.getInstance();
    _preferences = await Preferences.getInstance();

    final entries = await _keystore.entries;

    _keysSubject.add([
      ..._keysSubject.value,
      ...entries..sort(),
    ]);

    final currentPublicKey = _preferences.getCurrentPublicKey();

    final key = keys.firstWhereOrNull((e) => e.publicKey == currentPublicKey);

    currentKey = key ?? keys.firstOrNull;

    keysStream
        .transform<bool>(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) => sink.add(data.isNotEmpty),
          ),
        )
        .distinct()
        .listen((event) {
      if (!event) {
        loggedOutSubject.add(Object());
      }
    });
  }
}
