import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'provider/models/account_interaction.dart';
import 'provider/models/permissions.dart';
import 'provider/models/wallet_contract_type.dart';

class Preferences {
  static const _preferencesBoxName = 'nekoton_preferences';
  static const _permissionsBoxName = 'nekoton_permissions';
  static const _currentPublicKeyKey = 'current_public_key';
  static const _currentConnectionKey = 'current_connection';
  static Preferences? _instance;
  late final Box<dynamic> _preferencesBox;
  late final Box<Permissions> _permissionsBox;

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

  Future<void> _initialize() async {
    await Hive.initFlutter();
    Hive
      ..registerAdapter(PermissionsAdapter())
      ..registerAdapter(AccountInteractionAdapter())
      ..registerAdapter(WalletContractTypeAdapter());

    _preferencesBox = await Hive.openBox(_preferencesBoxName);
    _permissionsBox = await Hive.openBox(_permissionsBoxName);
  }
}
