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
import 'provider/models/contract_state_changed_event.dart';
import 'provider/models/contract_updates_subscription.dart';
import 'provider/models/transactions_found_event.dart';
import 'provider/provider_events.dart';
import 'transport/gql_transport.dart';

class SubscriptionsController {
  static SubscriptionsController? _instance;
  late final ConnectionController _connectionController;
  final _tonWalletsSubject = BehaviorSubject<List<TonWallet>>.seeded([]);
  final _tokenWalletsSubject = BehaviorSubject<List<TokenWallet>>.seeded([]);
  final _genericContractsSubject = BehaviorSubject<Map<String, List<GenericContract>>>.seeded({});

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

  Stream<Map<String, List<GenericContract>>> get genericContractsStream => _genericContractsSubject.stream.distinct();

  List<TonWallet> get tonWallets => _tonWalletsSubject.value;

  List<TokenWallet> get tokenWallets => _tokenWalletsSubject.value;

  Map<String, List<GenericContract>> get genericContracts => _genericContractsSubject.value;

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

    _tokenWalletsSubject.add(tokenWallets);

    return tokenWallet;
  }

  Future<void> subscribeToGenericContract({
    required String origin,
    required String address,
  }) async {
    final transport = _connectionController.transport as GqlTransport;

    final genericContract = await genericContractSubscribe(
      transport: transport,
      address: address,
    );

    final subscriptions = {..._genericContractsSubject.value};
    subscriptions[origin] = [...subscriptions[origin] ?? [], genericContract];

    _genericContractsSubject.add(subscriptions);

    genericContract.onStateChangedStream.listen((event) {
      providerContractStateChangedSubject.add(ContractStateChangedEvent(
        address: genericContract.address,
        state: event,
      ));
    });

    genericContract.onTransactionsFoundRawStream.listen((event) {
      providerTransactionsFoundSubject.add(TransactionsFoundEvent(
        address: genericContract.address,
        transactions: event.item1,
        info: event.item2,
      ));
    });
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

  void removeTokenWalletSubscription({
    required TonWalletAsset tonWalletAsset,
    required TokenWalletAsset tokenWalletAsset,
  }) {
    final tokenWallet = _tokenWalletsSubject.value.firstWhereOrNull(
        (e) => e.owner == tonWalletAsset.address && e.symbol.rootTokenContract == tokenWalletAsset.rootTokenContract);

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

  void removeOriginGenericContractSubscriptions(String origin) {
    final subscriptions = {..._genericContractsSubject.value};

    final genericContracts = subscriptions[origin];

    if (genericContracts == null) {
      return;
    }

    subscriptions[origin] = [];

    _genericContractsSubject.add(subscriptions);

    for (final genericContract in genericContracts) {
      freeGenericContract(genericContract);
    }
  }

  void removeGenericContractSubscription({
    required String origin,
    required String address,
  }) {
    final subscriptions = {..._genericContractsSubject.value};

    final genericContract = subscriptions[origin]?.firstWhereOrNull((e) => e.address == address);

    if (genericContract == null) {
      return;
    }

    subscriptions[origin] = [...subscriptions[origin]?.where((e) => e != genericContract) ?? []];

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
    final subscriptions = {..._genericContractsSubject.value};

    _genericContractsSubject.add({});

    for (final subscription in subscriptions.values.expand((e) => e)) {
      freeGenericContract(subscription);
    }
  }

  Map<String, ContractUpdatesSubscription> getOriginSubscriptions(String origin) {
    final originSubscriptions = [..._genericContractsSubject.value[origin] ?? []];

    final map = <String, ContractUpdatesSubscription>{};

    for (final subscription in originSubscriptions) {
      map[subscription.address] = const ContractUpdatesSubscription(state: true, transactions: true);
    }

    return map;
  }

  Future<void> _initialize() async {
    _connectionController = await ConnectionController.getInstance();
  }
}
