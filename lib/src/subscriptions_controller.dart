import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import 'connection_controller.dart';
import 'core/accounts_storage/models/wallet_type.dart';
import 'core/generic_contract/generic_contract.dart';
import 'core/token_wallet/token_wallet.dart';
import 'core/ton_wallet/ton_wallet.dart';
import 'provider/models/contract_updates_subscription.dart';
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

  Future<TokenWallet> subscribeToTokenWallet({
    required String owner,
    required String rootTokenContract,
  }) async {
    final existingTokenWallet = _tokenWalletsSubject.value.firstWhereOrNull(
      (e) => e.owner == owner && e.symbol.rootTokenContract == rootTokenContract,
    );

    if (existingTokenWallet != null) {
      return existingTokenWallet;
    }

    final transport = _connectionController.transport as GqlTransport;

    final tonWallet = tonWallets.firstWhere((e) => e.address == owner);

    final tokenWallet = await TokenWallet.subscribe(
      transport: transport,
      tonWallet: tonWallet,
      rootTokenContract: rootTokenContract,
    );

    final tokenWallets = [..._tokenWalletsSubject.value];

    tokenWallets
      ..add(tokenWallet)
      ..sort();

    _tokenWalletsSubject.add(tokenWallets);

    return tokenWallet;
  }

  Future<TonWallet> subscribeToTonWallet({
    required String address,
    required int workchain,
    required String publicKey,
    required WalletType walletType,
  }) async {
    final existingTonWallet = _tonWalletsSubject.value.firstWhereOrNull((e) => e.address == address);

    if (existingTonWallet != null) {
      return existingTonWallet;
    }

    final transport = _connectionController.transport as GqlTransport;

    final tonWallet = await TonWallet.subscribe(
      transport: transport,
      workchain: workchain,
      publicKey: publicKey,
      walletType: walletType,
    );

    final tonWallets = [..._tonWalletsSubject.value];

    tonWallets
      ..add(tonWallet)
      ..sort();

    _tonWalletsSubject.add(tonWallets);

    return tonWallet;
  }

  Future<TonWallet> subscribeByAddressToTonWallet(String address) async {
    final existingTonWallet = _tonWalletsSubject.value.firstWhereOrNull((e) => e.address == address);

    if (existingTonWallet != null) {
      return existingTonWallet;
    }

    final transport = _connectionController.transport as GqlTransport;

    final tonWallet = await TonWallet.subscribeByAddress(
      transport: transport,
      address: address,
    );

    final tonWallets = [..._tonWalletsSubject.value];

    tonWallets
      ..add(tonWallet)
      ..sort();

    _tonWalletsSubject.add(tonWallets);

    return tonWallet;
  }

  Future<GenericContract> subscribeToGenericContract({
    required String origin,
    required String address,
  }) async {
    final transport = _connectionController.transport as GqlTransport;

    final genericContract = await GenericContract.subscribe(
      transport: transport,
      address: address,
    );

    final subscriptions = {..._genericContractsSubject.value};
    subscriptions[origin] = [...subscriptions[origin] ?? [], genericContract];

    _genericContractsSubject.add(subscriptions);

    return genericContract;
  }

  Future<void> removeTonWalletSubscription(String address) async {
    final tonWallet = _tonWalletsSubject.value.firstWhereOrNull((e) => e.address == address);

    if (tonWallet == null) {
      return;
    }

    final subscriptions = [..._tonWalletsSubject.value];

    subscriptions
      ..remove(tonWallet)
      ..sort();

    _tonWalletsSubject.add(subscriptions);

    await tonWallet.free();
  }

  Future<void> removeTokenWalletSubscription({
    required String owner,
    required String rootTokenContract,
  }) async {
    final tokenWallet = _tokenWalletsSubject.value.firstWhereOrNull(
      (e) => e.owner == owner && e.symbol.rootTokenContract == rootTokenContract,
    );

    if (tokenWallet == null) {
      return;
    }

    final subscriptions = [..._tokenWalletsSubject.value];

    subscriptions
      ..remove(tokenWallet)
      ..sort();

    _tokenWalletsSubject.add(subscriptions);

    await tokenWallet.free();
  }

  Future<void> removeOriginGenericContractSubscriptions(String origin) async {
    final subscriptions = {..._genericContractsSubject.value};

    final genericContracts = subscriptions[origin];

    if (genericContracts == null) {
      return;
    }

    subscriptions[origin] = [];

    _genericContractsSubject.add(subscriptions);

    for (final genericContract in genericContracts) {
      await genericContract.free();
    }
  }

  Future<void> removeGenericContractSubscription({
    required String origin,
    required String address,
  }) async {
    final subscriptions = {..._genericContractsSubject.value};

    final genericContract = subscriptions[origin]?.firstWhereOrNull((e) => e.address == address);

    if (genericContract == null) {
      return;
    }

    subscriptions[origin] = [...subscriptions[origin]?.where((e) => e != genericContract) ?? []];

    _genericContractsSubject.add(subscriptions);

    await genericContract.free();
  }

  Future<void> clearTonWalletsSubscriptions() async {
    final subscriptions = [..._tonWalletsSubject.value];

    _tonWalletsSubject.add([]);

    for (final subscription in subscriptions) {
      await subscription.free();
    }
  }

  Future<void> clearTokenWalletsSubscriptions() async {
    final subscriptions = [..._tokenWalletsSubject.value];

    _tokenWalletsSubject.add([]);

    for (final subscription in subscriptions) {
      await subscription.free();
    }
  }

  Future<void> clearGenericContractsSubscriptions() async {
    final subscriptions = {..._genericContractsSubject.value};

    _genericContractsSubject.add({});

    for (final subscription in subscriptions.values.expand((e) => e)) {
      await subscription.free();
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
