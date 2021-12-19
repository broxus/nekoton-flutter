import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import '../nekoton_flutter.dart';
import 'connection_controller.dart';
import 'core/accounts_storage/models/assets_list.dart';
import 'core/accounts_storage/models/token_wallet_asset.dart';
import 'core/token_wallet/get_token_wallet_info.dart';
import 'models/nekoton_exception.dart';
import 'preferences.dart';
import 'transport/gql_transport.dart';

class ExternalAccountsController {
  static ExternalAccountsController? _instance;
  late final Preferences _preferences;
  late final ConnectionController _connectionController;
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

  Future<AssetsList> addExternalAccountTokenWallet({
    required String publicKey,
    required String address,
    required String rootTokenContract,
  }) async {
    final transport = _connectionController.transport as GqlTransport;

    try {
      await getTokenWalletInfo(
        transport: transport,
        owner: address,
        rootTokenContract: rootTokenContract,
      );
    } catch (err) {
      throw InvalidRootTokenContractException();
    }

    final networkGroup = _connectionController.transport.connectionData.group;

    final accounts = _preferences.getExternalAccounts()[publicKey];

    if (accounts == null) {
      throw ExternalAccountNotFoundException();
    }

    final account = accounts.firstWhereOrNull((e) => e.address == address);

    if (account == null) {
      throw ExternalAccountNotFoundException();
    }

    if (account.additionalAssets[networkGroup]?.tokenWallets.any((e) => e.rootTokenContract == rootTokenContract) ??
        false) {
      throw ExternalAccountTokenWalletAlreadyAddedException();
    }

    final tokenWalletAsset = TokenWalletAsset(rootTokenContract: rootTokenContract);

    final tokenWallets = account.additionalAssets[networkGroup]?.tokenWallets ?? [];

    tokenWallets.add(tokenWalletAsset);

    final additionalAssets = account.additionalAssets[networkGroup] ??
        AdditionalAssets(
          tokenWallets: tokenWallets,
          depools: [],
        );

    final map = {
      ...account.additionalAssets,
      networkGroup: additionalAssets,
    };

    final updatedAccount = account.copyWith(additionalAssets: map);

    await _preferences.removeExternalAccount(
      publicKey: publicKey,
      address: address,
    );

    final addedAssetsList = await _preferences.addExternalAccount(
      publicKey: publicKey,
      assetsList: updatedAccount,
    );

    _externalAccountsSubject.value = _preferences.getExternalAccounts();

    return addedAssetsList;
  }

  Future<AssetsList> removeExternalAccountTokenWallet({
    required String publicKey,
    required String address,
    required String rootTokenContract,
  }) async {
    final transport = _connectionController.transport as GqlTransport;

    try {
      await getTokenWalletInfo(
        transport: transport,
        owner: address,
        rootTokenContract: rootTokenContract,
      );
    } catch (err) {
      throw InvalidRootTokenContractException();
    }

    final networkGroup = _connectionController.transport.connectionData.group;

    final accounts = _preferences.getExternalAccounts()[publicKey];

    if (accounts == null) {
      throw ExternalAccountNotFoundException();
    }

    final account = accounts.firstWhereOrNull((e) => e.address == address);

    if (account == null) {
      throw ExternalAccountNotFoundException();
    }

    if (account.additionalAssets[networkGroup]?.tokenWallets.any((e) => e.rootTokenContract != rootTokenContract) ??
        true) {
      throw ExternalAccountTokenWalletNotFoundException();
    }

    final tokenWallets = account.additionalAssets[networkGroup]!.tokenWallets
        .where((e) => e.rootTokenContract != rootTokenContract)
        .toList();

    final additionalAssets = account.additionalAssets[networkGroup] ??
        AdditionalAssets(
          tokenWallets: tokenWallets,
          depools: [],
        );

    final map = {
      ...account.additionalAssets,
      networkGroup: additionalAssets,
    };

    final updatedAccount = account.copyWith(additionalAssets: map);

    await _preferences.removeExternalAccount(
      publicKey: publicKey,
      address: address,
    );

    final addedAssetsList = await _preferences.addExternalAccount(
      publicKey: publicKey,
      assetsList: updatedAccount,
    );

    _externalAccountsSubject.value = _preferences.getExternalAccounts();

    return addedAssetsList;
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
    _connectionController = await ConnectionController.getInstance();

    _externalAccountsSubject.value = _preferences.getExternalAccounts();
  }
}
