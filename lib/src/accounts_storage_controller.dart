import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import 'connection_controller.dart';
import 'constants.dart';
import 'core/accounts_storage/accounts_storage.dart';
import 'core/accounts_storage/models/assets_list.dart';
import 'core/accounts_storage/models/wallet_type.dart';
import 'core/token_wallet/token_wallet.dart';
import 'core/ton_wallet/ton_wallet.dart';
import 'models/nekoton_exception.dart';
import 'transport/gql_transport.dart';

class AccountsStorageController {
  static AccountsStorageController? _instance;
  late final AccountsStorage _accountsStorage;
  late final ConnectionController _connectionController;
  final _accountsSubject = BehaviorSubject<List<AssetsList>>.seeded([]);

  AccountsStorageController._();

  static Future<AccountsStorageController> getInstance() async {
    if (_instance == null) {
      final instance = AccountsStorageController._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Stream<List<AssetsList>> get accountsStream => _accountsSubject.stream.distinct();

  List<AssetsList> get accounts => _accountsSubject.value;

  Future<AssetsList> addAccount({
    required String name,
    required String publicKey,
    required WalletType walletType,
    required int workchain,
  }) async {
    final account = await _accountsStorage.addAccount(
      name: name,
      publicKey: publicKey,
      walletType: walletType,
      workchain: workchain,
    );

    final accounts = [..._accountsSubject.value];

    accounts
      ..add(account)
      ..sort();

    _accountsSubject.add(accounts);

    return account;
  }

  Future<List<AssetsList>> findExistingAccounts(String publicKey) async {
    final transport = _connectionController.transport as GqlTransport;

    final wallets = await findExistingWallets(
      transport: transport,
      publicKey: publicKey,
      workchainId: kDefaultWorkchain,
    );

    final activeWallets = wallets.where((e) => e.contractState.isDeployed || e.contractState.balance != '0');

    final accounts = <AssetsList>[];

    for (final activeWallet in activeWallets) {
      final account = await addAccount(
        name: activeWallet.walletType.describe(),
        publicKey: publicKey,
        walletType: activeWallet.walletType,
        workchain: kDefaultWorkchain,
      );
      accounts.add(account);
    }

    return accounts;
  }

  Future<AssetsList> renameAccount({
    required String address,
    required String name,
  }) async {
    final accounts = [..._accountsSubject.value];

    final account = await _accountsStorage.renameAccount(
      address: address,
      name: name,
    );

    accounts
      ..removeWhere((e) => e.address == account.address)
      ..add(account)
      ..sort();

    _accountsSubject.add(accounts);

    return account;
  }

  Future<AssetsList?> removeAccount(String address) async {
    final account = _accountsSubject.value.firstWhereOrNull((e) => e.address == address);

    if (account == null) {
      return null;
    }

    final accounts = [..._accountsSubject.value];

    accounts
      ..removeWhere((e) => e.address == account.address)
      ..sort();

    _accountsSubject.add(accounts);

    await _accountsStorage.removeAccount(account.address);

    return account;
  }

  Future<AssetsList> addTokenWallet({
    required String address,
    required String rootTokenContract,
  }) async {
    final transport = _connectionController.transport as GqlTransport;

    final isValid = await checkTokenWalletValidity(
      transport: transport,
      owner: address,
      rootTokenContract: rootTokenContract,
    );

    if (!isValid) {
      throw InvalidRootTokenContractException();
    }

    final networkGroup = _connectionController.transport.connectionData.group;

    final accounts = [..._accountsSubject.value];

    final account = await _accountsStorage.addTokenWallet(
      address: address,
      rootTokenContract: rootTokenContract,
      networkGroup: networkGroup,
    );

    accounts
      ..removeWhere((e) => e.address == account.address)
      ..add(account)
      ..sort();

    _accountsSubject.add(accounts);

    return account;
  }

  Future<AssetsList> removeTokenWallet({
    required String address,
    required String rootTokenContract,
  }) async {
    final networkGroup = _connectionController.transport.connectionData.group;

    final accounts = [..._accountsSubject.value];

    final account = await _accountsStorage.removeTokenWallet(
      address: address,
      rootTokenContract: rootTokenContract,
      networkGroup: networkGroup,
    );

    accounts
      ..removeWhere((e) => e.address == account.address)
      ..add(account)
      ..sort();

    _accountsSubject.add(accounts);

    return account;
  }

  Future<void> clearAccountsStorage() async {
    _accountsSubject.add([]);

    await _accountsStorage.clear();
  }

  Future<void> _initialize() async {
    _accountsStorage = await AccountsStorage.getInstance();
    _connectionController = await ConnectionController.getInstance();

    final accounts = await _accountsStorage.accounts;

    _accountsSubject.add([
      ..._accountsSubject.value,
      ...accounts..sort(),
    ]);
  }
}
