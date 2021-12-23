import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import 'accounts_storage_controller.dart';
import 'connection_controller.dart';
import 'core/accounts_storage/models/wallet_type.dart';
import 'core/ton_wallet/get_ton_wallet_info.dart';
import 'keystore_controller.dart';
import 'models/nekoton_exception.dart';
import 'preferences.dart';
import 'transport/gql_transport.dart';

class ExternalAccountsController {
  static ExternalAccountsController? _instance;
  late final AccountsStorageController _accountsStorageController;
  late final ConnectionController _connectionController;
  late final KeystoreController _keystoreController;
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
    String? name,
  }) async {
    final tonWalletInfo = await getTonWalletInfo(
      transport: _connectionController.transport as GqlTransport,
      address: address,
    );

    final custodians = tonWalletInfo.custodians ?? [];

    final isCustodian = custodians.any((e) => e == publicKey);

    if (!isCustodian) {
      throw ExternalAccountNonCustodianException();
    }

    if (publicKey == tonWalletInfo.publicKey) {
      throw AccountAlreadyAddedException();
    }

    final isExists = _accountsStorageController.accounts.any((e) => e.address == address);

    if (!isExists) {
      await _accountsStorageController.addAccount(
        name: name ?? tonWalletInfo.walletType.describe(),
        publicKey: tonWalletInfo.publicKey,
        walletType: tonWalletInfo.walletType,
        workchain: tonWalletInfo.workchain,
      );
    } else if (name != null) {
      await _accountsStorageController.renameAccount(
        address: address,
        name: name,
      );
    }

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

    final account = _accountsStorageController.accounts.firstWhereOrNull((e) => e.address == address);

    if (account != null) {
      final tonWalletInfo = await getTonWalletInfo(
        transport: _connectionController.transport as GqlTransport,
        address: account.address,
      );

      final custodians = tonWalletInfo.custodians ?? [];

      final keys = _keystoreController.keys.map((e) => e.publicKey);

      final isExists = keys.any((e) => custodians.any((el) => el == e));

      if (!isExists) {
        await _accountsStorageController.removeAccount(account.address);
      }
    }
  }

  Future<void> clearExternalAccounts() async {
    await _preferences.clearExternalAccounts();

    _externalAccountsSubject.add(_preferences.getExternalAccounts());
  }

  Future<void> _initialize() async {
    _preferences = await Preferences.getInstance();
    _accountsStorageController = await AccountsStorageController.getInstance();
    _connectionController = await ConnectionController.getInstance();
    _keystoreController = await KeystoreController.getInstance();

    _externalAccountsSubject.add(_preferences.getExternalAccounts());
  }
}
