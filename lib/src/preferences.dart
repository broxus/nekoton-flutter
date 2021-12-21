import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import 'provider/models/permissions.dart';

class Preferences {
  static const _preferencesBoxName = 'nekoton_preferences';
  static const _permissionsBoxName = 'nekoton_permissions';
  static const _externalAccountsBoxName = 'nekoton_external_accounts';
  static const _currentPublicKeyKey = 'current_public_key';
  static const _currentConnectionKey = 'current_connection';
  static Preferences? _instance;
  late final Box<dynamic> _preferencesBox;
  late final Box<Permissions> _permissionsBox;
  late final Box<List> _externalAccountsBox;

  Preferences._();

  static Future<Preferences> getInstance() async {
    if (_instance == null) {
      final instance = Preferences._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  String? getCurrentPublicKey() => _preferencesBox.get(_currentPublicKeyKey) as String?;

  Future<void> setCurrentPublicKey(String? currentPublicKey) => _preferencesBox.put(
        _currentPublicKeyKey,
        currentPublicKey,
      );

  String? getCurrentConnection() => _preferencesBox.get(_currentConnectionKey) as String?;

  Future<void> setCurrentConnection(String? currentConnection) => _preferencesBox.put(
        _currentConnectionKey,
        currentConnection,
      );

  Permissions getPermissions(String origin) => _permissionsBox.get(origin) ?? const Permissions();

  Future<void> setPermissions({
    required String origin,
    required Permissions permissions,
  }) =>
      _permissionsBox.put(origin, permissions);

  Future<void> deletePermissions(String origin) => _permissionsBox.delete(origin);

  Future<void> deletePermissionsForAccount(String address) async {
    final newValues = _permissionsBox.values.where((e) => e.accountInteraction?.address != address);

    await _permissionsBox.clear();
    await _permissionsBox.addAll(newValues);
  }

  Map<String, List<String>> getExternalAccounts() =>
      _externalAccountsBox.toMap().map((key, value) => MapEntry(key as String, value.cast<String>()));

  Future<void> addExternalAccount({
    required String publicKey,
    required String address,
  }) async {
    final list = _externalAccountsBox.get(publicKey)?.cast<String>().where((e) => e != address).toList() ?? [];

    list.add(address);

    await _externalAccountsBox.put(publicKey, list);
  }

  Future<void> removeExternalAccount({
    required String publicKey,
    required String address,
  }) async {
    final list = _externalAccountsBox.get(publicKey)?.cast<String>().where((e) => e != address).toList();

    if (list == null) return;

    if (list.isNotEmpty) {
      await _externalAccountsBox.put(publicKey, list);
    } else {
      await _externalAccountsBox.delete(publicKey);
    }
  }

  Future<void> clearExternalAccounts() => _externalAccountsBox.clear();

  Future<void> _initialize() async {
    _preferencesBox = await Hive.openBox(_preferencesBoxName);
    _permissionsBox = await Hive.openBox(_permissionsBoxName);
    _externalAccountsBox = await Hive.openBox(_externalAccountsBoxName);
  }
}
