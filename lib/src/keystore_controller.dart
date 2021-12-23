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

  Stream<List<KeyStoreEntry>> get keysStream => _keysSubject.stream;

  List<KeyStoreEntry> get keys => _keysSubject.value;

  Stream<KeyStoreEntry?> get currentKeyStream => _currentKeySubject.stream;

  KeyStoreEntry? get currentKey => _currentKeySubject.value;

  Future<void> setCurrentKey(KeyStoreEntry? currentKey) async {
    _currentKeySubject.add(currentKey);
    await _preferences.setCurrentPublicKey(currentKey?.publicKey);
  }

  Future<KeyStoreEntry> addKey(CreateKeyInput createKeyInput) async {
    final key = await _keystore.addKey(createKeyInput);

    _keysSubject.add(await _keystore.entries);

    if (currentKey == null) {
      await setCurrentKey(key);
    }

    return key;
  }

  Future<KeyStoreEntry> updateKey(UpdateKeyInput updateKeyInput) async {
    final key = await _keystore.updateKey(updateKeyInput);

    _keysSubject.add(await _keystore.entries);

    return key;
  }

  Future<ExportKeyOutput> exportKey(ExportKeyInput exportKeyInput) => _keystore.exportKey(exportKeyInput);

  Future<bool> checkKeyPassword(SignInput signInput) => _keystore.checkKeyPassword(signInput);

  Future<SignInput> getSignInput({
    required String publicKey,
    required String password,
  }) =>
      _keystore.getSignInput(
        publicKey: publicKey,
        password: password,
      );

  Future<KeyStoreEntry?> removeKey(String publicKey) async {
    final key = await _keystore.removeKey(publicKey);

    _keysSubject.add(await _keystore.entries);

    final derivedKeys = _keysSubject.value.where((e) => e.masterKey == publicKey).map((e) => e.publicKey);

    for (final key in derivedKeys) {
      await removeKey(key);
    }

    return key;
  }

  Future<void> clearKeystore() async {
    await _keystore.clear();

    _keysSubject.add(await _keystore.entries);

    await setCurrentKey(await _keystore.entries.then((e) => e.firstOrNull));
  }

  Future<void> _initialize() async {
    _keystore = await Keystore.getInstance();
    _preferences = await Preferences.getInstance();

    _keysSubject.add(await _keystore.entries);

    final currentPublicKey = _preferences.getCurrentPublicKey();

    final key = keys.firstWhereOrNull((e) => e.publicKey == currentPublicKey);

    await setCurrentKey(key ?? keys.firstOrNull);

    keysStream.map((e) => e.isNotEmpty).listen((event) {
      if (!event) {
        loggedOutSubject.add(Object());
      }
    });
  }
}
