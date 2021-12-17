import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'core/accounts_storage/models/assets_list.dart';
import 'preferences.dart';

class ExternalAccountsController {
  static ExternalAccountsController? _instance;
  late final Preferences _preferences;
  final _externalAccountsSubject = BehaviorSubject<Map<String, List<AssetsList>>>.seeded({});

  ExternalAccountsController._();

  static Future<ExternalAccountsController> getInstance() async {
    if (_instance == null) {
      final instance = ExternalAccountsController._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Stream<Map<String, List<AssetsList>>> get externalAccountsStream => _externalAccountsSubject.stream;

  Map<String, List<AssetsList>> get externalAccounts => _externalAccountsSubject.value;

  Future<AssetsList> addExternalAccount({
    required String publicKey,
    required AssetsList assetsList,
  }) async {
    final addedAssetsList = await _preferences.addExternalAccount(
      publicKey: publicKey,
      assetsList: assetsList,
    );

    _externalAccountsSubject.value = _preferences.getExternalAccounts();

    return addedAssetsList;
  }

  Future<AssetsList> renameExternalAccount({
    required String publicKey,
    required String address,
    required String name,
  }) async {
    final assetsList = await _preferences.renameExternalAccount(
      publicKey: publicKey,
      address: address,
      name: name,
    );

    _externalAccountsSubject.value = _preferences.getExternalAccounts();

    return assetsList;
  }

  Future<AssetsList?> removeExternalAccount({
    required String publicKey,
    required String address,
  }) async {
    final assetsList = await _preferences.removeExternalAccount(
      publicKey: publicKey,
      address: address,
    );

    _externalAccountsSubject.value = _preferences.getExternalAccounts();

    return assetsList;
  }

  Future<void> removeExternalAccounts(String publicKey) async {
    await _preferences.removeExternalAccounts(publicKey);

    _externalAccountsSubject.value = _preferences.getExternalAccounts();
  }

  Future<void> clearExternalAccounts() async {
    await _preferences.clearExternalAccounts();

    _externalAccountsSubject.value = _preferences.getExternalAccounts();
  }

  Future<void> _initialize() async {
    _preferences = await Preferences.getInstance();

    _externalAccountsSubject.value = _preferences.getExternalAccounts();
  }
}
