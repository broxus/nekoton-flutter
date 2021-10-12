import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'provider/models/account_interaction.dart';
import 'provider/models/permissions.dart';
import 'provider/models/wallet_contract_type.dart';

class Preferences {
  static const currentPublicKeyKey = "current_public_key";
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

  String? getCurrentPublicKey() => _preferencesBox.get(currentPublicKeyKey) as String?;

  Future<void> setCurrentPublicKey(String? currentPublicKey) => _preferencesBox.put(
        currentPublicKeyKey,
        currentPublicKey,
      );

  Permissions getPermissions(String origin) => _permissionsBox.get(origin) ?? const Permissions();

  Future<void> setPermissions({
    required String origin,
    required Permissions permissions,
  }) async =>
      _permissionsBox.put(origin, permissions);

  Future<void> deletePermissions(String origin) async => _permissionsBox.delete(origin);

  Future<void> _initialize() async {
    await Hive.initFlutter();
    Hive
      ..registerAdapter(PermissionsAdapter())
      ..registerAdapter(AccountInteractionAdapter())
      ..registerAdapter(WalletContractTypeAdapter());

    _preferencesBox = await Hive.openBox("nekoton_preferences");
    _permissionsBox = await Hive.openBox("nekoton_permissions");
  }
}
