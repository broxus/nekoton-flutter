import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import 'connection_controller.dart';
import 'core/accounts_storage/models/assets_list.dart';
import 'core/accounts_storage/models/token_wallet_asset.dart';
import 'core/accounts_storage/models/ton_wallet_asset.dart';
import 'core/generic_contract/generic_contract.dart';
import 'core/token_wallet/token_wallet.dart';
import 'core/ton_wallet/ton_wallet.dart';
import 'helpers/helpers.dart';
import 'models/nekoton_exception.dart';
import 'transport/gql_transport.dart';

class SubscriptionsController {
  static SubscriptionsController? _instance;
  late final ConnectionController _connectionController;
  final _tonWalletsSubject = BehaviorSubject<List<TonWallet>>.seeded([]);
  final _tokenWalletsSubject = BehaviorSubject<List<TokenWallet>>.seeded([]);
  final _genericContractsSubject = BehaviorSubject<List<GenericContract>>.seeded([]);

  SubscriptionsController._();

  static Future<SubscriptionsController> getInstance() async {
    if (_instance == null) {
      final instance = SubscriptionsController._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Stream<List<TonWallet>> get tonWalletsStream => _tonWalletsSubject.stream.distinct();

  Stream<List<TokenWallet>> get tokenWalletsStream => _tokenWalletsSubject.stream.distinct();

  Stream<List<GenericContract>> get genericContractsStream => _genericContractsSubject.stream.distinct();

  List<TonWallet> get tonWallets => _tonWalletsSubject.value;

  List<TokenWallet> get tokenWallets => _tokenWalletsSubject.value;

  List<GenericContract> get genericContracts => _genericContractsSubject.value;

  Future<void> updateCurrentSubscriptions({
    required String publicKey,
    required List<AssetsList> accounts,
  }) async {
    clearTonWalletsSubscriptions();
    clearTokenWalletsSubscriptions();

    for (final account in accounts) {
      await subscribeToTonWallet(
        publicKey: publicKey,
        tonWalletAsset: account.tonWallet,
      );

      final networkGroup = _connectionController.transport.connectionData.group;

      final tokenWalletAssets = [...account.additionalAssets[networkGroup]?.tokenWallets ?? []];

      for (final tokenWalletAsset in tokenWalletAssets) {
        await subscribeToTokenWallet(
          tonWalletAsset: account.tonWallet,
          tokenWalletAsset: tokenWalletAsset,
        );
      }
    }
  }

  Future<TonWallet> subscribeToTonWallet({
    required String publicKey,
    required TonWalletAsset tonWalletAsset,
  }) async {
    final transport = _connectionController.transport as GqlTransport;

    final tonWallet = await tonWalletSubscribe(
      transport: transport,
      workchain: tonWalletAsset.workchain,
      publicKey: publicKey,
      walletType: tonWalletAsset.contract,
    );

    final tonWallets = [..._tonWalletsSubject.value];

    tonWallets
      ..add(tonWallet)
      ..sort();

    _tonWalletsSubject.add(tonWallets);

    return tonWallet;
  }

  Future<TokenWallet> subscribeToTokenWallet({
    required TonWalletAsset tonWalletAsset,
    required TokenWalletAsset tokenWalletAsset,
  }) async {
    final transport = _connectionController.transport as GqlTransport;

    final tonWallet = tonWallets.firstWhere((e) => e.address == tonWalletAsset.address);

    final tokenWallet = await tokenWalletSubscribe(
      transport: transport,
      tonWallet: tonWallet,
      rootTokenContract: tokenWalletAsset.rootTokenContract,
    );

    final tokenWallets = [..._tokenWalletsSubject.value];

    tokenWallets
      ..add(tokenWallet)
      ..sort();

    _tonWalletsSubject.add(tonWallets);

    return tokenWallet;
  }

  Future<void> subscribeToGenericContract(String address) async {
    if (!validateAddress(address)) {
      throw InvalidAddressException();
    }

    final transport = _connectionController.transport as GqlTransport;

    final genericContract = await genericContractSubscribe(
      transport: transport,
      address: address,
    );

    final subscriptions = [..._genericContractsSubject.value, genericContract];

    _genericContractsSubject.add(subscriptions);
  }

  void removeTonWalletSubscription(TonWalletAsset tonWalletAsset) {
    final tonWallet = _tonWalletsSubject.value.firstWhereOrNull((e) => e.address == tonWalletAsset.address);

    if (tonWallet == null) {
      return;
    }

    final subscriptions = [..._tonWalletsSubject.value];

    subscriptions
      ..remove(tonWallet)
      ..sort();

    _tonWalletsSubject.add(subscriptions);

    freeTonWallet(tonWallet);
  }

  void removeTokenWalletSubscription(TokenWalletAsset tokenWalletAsset) {
    final tokenWallet = _tokenWalletsSubject.value
        .firstWhereOrNull((e) => e.symbol.rootTokenContract == tokenWalletAsset.rootTokenContract);

    if (tokenWallet == null) {
      return;
    }

    final subscriptions = [..._tokenWalletsSubject.value];

    subscriptions
      ..remove(tokenWallet)
      ..sort();

    _tokenWalletsSubject.add(subscriptions);

    freeTokenWallet(tokenWallet);
  }

  void removeGenericContractSubscription(String address) {
    final genericContract = _genericContractsSubject.value.firstWhereOrNull((e) => e.address == address);

    if (genericContract == null) {
      return;
    }

    final subscriptions = [..._genericContractsSubject.value];

    subscriptions.remove(genericContract);

    _genericContractsSubject.add(subscriptions);

    freeGenericContract(genericContract);
  }

  void clearTonWalletsSubscriptions() {
    final subscriptions = [..._tonWalletsSubject.value];

    _tonWalletsSubject.add([]);

    for (final subscription in subscriptions) {
      freeTonWallet(subscription);
    }
  }

  void clearTokenWalletsSubscriptions() {
    final subscriptions = [..._tokenWalletsSubject.value];

    _tokenWalletsSubject.add([]);

    for (final subscription in subscriptions) {
      freeTokenWallet(subscription);
    }
  }

  void clearGenericContractsSubscriptions() {
    final subscriptions = [..._genericContractsSubject.value];

    _genericContractsSubject.add([]);

    for (final subscription in subscriptions) {
      freeGenericContract(subscription);
    }
  }

  Future<void> _initialize() async {
    _connectionController = await ConnectionController.getInstance();
  }
}
