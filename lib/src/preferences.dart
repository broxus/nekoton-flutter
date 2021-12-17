import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/accounts_storage/models/assets_list.dart';
import 'core/accounts_storage/models/wallet_type.dart';
import 'core/models/contract_state.dart';
import 'core/models/gen_timings.dart';
import 'core/models/last_transaction_id.dart';
import 'core/token_wallet/models/symbol.dart';
import 'core/token_wallet/models/token_wallet_version.dart';
import 'core/ton_wallet/models/ton_wallet_details.dart';
import 'core/ton_wallet/models/ton_wallet_info.dart';
import 'provider/models/account_interaction.dart';
import 'provider/models/permissions.dart';
import 'provider/models/wallet_contract_type.dart';

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

  Map<String, List<AssetsList>> getExternalAccounts() =>
      _externalAccountsBox.toMap().map((key, value) => MapEntry(key as String, value.cast<AssetsList>()));

  Future<AssetsList> addExternalAccount({
    required String publicKey,
    required AssetsList assetsList,
  }) async {
    final list = _externalAccountsBox
            .get(publicKey)
            ?.cast<AssetsList>()
            .where((e) => e.address != assetsList.address)
            .toList() ??
        [];

    list.add(assetsList);

    await _externalAccountsBox.put(publicKey, list);

    return _externalAccountsBox.get(publicKey)!.cast<AssetsList>().firstWhere((e) => e == assetsList);
  }

  Future<AssetsList> renameExternalAccount({
    required String publicKey,
    required String address,
    required String name,
  }) async {
    final list = _externalAccountsBox.get(publicKey)!.cast<AssetsList>();

    final assetsList = list.firstWhere((e) => e.address == address);

    list
      ..remove(assetsList)
      ..add(assetsList.copyWith(name: name));

    await _externalAccountsBox.put(publicKey, list);

    return assetsList;
  }

  Future<AssetsList?> removeExternalAccount({
    required String publicKey,
    required String address,
  }) async {
    final assetsList =
        _externalAccountsBox.get(publicKey)?.cast<AssetsList>().firstWhereOrNull((e) => e.address == address);

    if (assetsList == null) return null;

    final list = _externalAccountsBox.get(publicKey)!.cast<AssetsList>().where((e) => e.address != address).toList();

    if (list.isNotEmpty) {
      await _externalAccountsBox.put(publicKey, list);
    } else {
      await _externalAccountsBox.delete(publicKey);
    }

    return assetsList;
  }

  Future<void> removeExternalAccounts(String publicKey) => _externalAccountsBox.delete(publicKey);

  Future<void> clearExternalAccounts() => _externalAccountsBox.clear();

  Future<void> _initialize() async {
    await Hive.initFlutter();
    Hive
      ..registerAdapter(WalletContractTypeAdapter())
      ..registerAdapter(PermissionsAdapter())
      ..registerAdapter(AccountInteractionAdapter())
      ..registerAdapter(TonWalletInfoAdapter())
      ..registerAdapter(TonWalletDetailsAdapter())
      ..registerAdapter(TokenWalletVersionAdapter())
      ..registerAdapter(SymbolAdapter())
      ..registerAdapter(LastTransactionIdAdapter())
      ..registerAdapter(GenTimingsAdapter())
      ..registerAdapter(ContractStateAdapter())
      ..registerAdapter(WalletV3Adapter())
      ..registerAdapter(MultisigAdapter());

    await Hive.deleteBoxFromDisk(_externalAccountsBoxName);

    _preferencesBox = await Hive.openBox(_preferencesBoxName);
    _permissionsBox = await Hive.openBox(_permissionsBoxName);
    _externalAccountsBox = await Hive.openBox(_externalAccountsBoxName);
  }
}
