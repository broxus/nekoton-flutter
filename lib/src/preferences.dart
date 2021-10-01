import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'provider/models/permissions.dart';

class Preferences {
  static const currentPublicKeyKey = "current_public_key";
  static Preferences? _instance;
  late final Box<dynamic> _preferencesBox;
  late final Box<String> _permissionsBox;

  Preferences._();

  static Future<Preferences> getInstance() async {
    if (_instance == null) {
      final instance = Preferences._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Future<String?> get currentPublicKey async => _preferencesBox.get(currentPublicKeyKey) as String?;

  Future<void> setCurrentPublicKey(String? currentPublicKey) => _preferencesBox.put(
        currentPublicKeyKey,
        currentPublicKey,
      );

  Future<Permissions?> getPermissions(String origin) async {
    final string = _permissionsBox.get(origin);

    if (string == null) {
      return null;
    }

    final permissions = Permissions.fromJson(jsonDecode(string) as Map<String, dynamic>);

    return permissions;
  }

  Future<void> setPermissions({
    required String origin,
    required Permissions permissions,
  }) async {
    final string = jsonEncode(permissions.toJson());

    await _permissionsBox.put(origin, string);
  }

  Future<void> deletePermissions(String origin) async => _permissionsBox.delete(origin);

  Future<void> _initialize() async {
    await Hive.initFlutter();
    _preferencesBox = await Hive.openBox("nekoton_preferences");
    _permissionsBox = await Hive.openBox("nekoton_permissions");
  }
}
