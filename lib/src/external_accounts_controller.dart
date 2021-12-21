import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'preferences.dart';

class ExternalAccountsController {
  static ExternalAccountsController? _instance;
  late final Preferences _preferences;
  final _externalAccountsSubject = BehaviorSubject<Map<String, List<String>>>.seeded({});

  ExternalAccountsController._();

  static Future<ExternalAccountsController> getInstance() async {
    if (_instance == null) {
      final instance = ExternalAccountsController._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Stream<Map<String, List<String>>> get externalAccountsStream => _externalAccountsSubject.stream;

  Map<String, List<String>> get externalAccounts => _externalAccountsSubject.value;

  Future<void> addExternalAccount({
    required String publicKey,
    required String address,
  }) async {
    await _preferences.addExternalAccount(
      publicKey: publicKey,
      address: address,
    );

    _externalAccountsSubject.add(_preferences.getExternalAccounts());
  }

  Future<void> removeExternalAccount({
    required String publicKey,
    required String address,
  }) async {
    await _preferences.removeExternalAccount(
      publicKey: publicKey,
      address: address,
    );

    _externalAccountsSubject.add(_preferences.getExternalAccounts());
  }

  Future<void> clearExternalAccounts() async {
    await _preferences.clearExternalAccounts();

    _externalAccountsSubject.add({});
  }

  Future<void> _initialize() async {
    _preferences = await Preferences.getInstance();

    _externalAccountsSubject.add(_preferences.getExternalAccounts());
  }
}
