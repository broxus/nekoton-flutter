import 'dart:async';

import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart';

import 'accounts_storage_controller.dart';
import 'approval_controller.dart';
import 'connection_controller.dart';
import 'core/accounts_storage/models/assets_list.dart';
import 'core/keystore/models/key_store_entry.dart';
import 'core/token_wallet/token_wallet.dart';
import 'core/ton_wallet/ton_wallet.dart';
import 'keystore_controller.dart';
import 'permissions_controller.dart';
import 'subscriptions_controller.dart';
import 'transport/transport.dart';

Logger? nekotonLogger;

class Nekoton {
  static Nekoton? _instance;
  static final _lock = Lock();
  late final KeystoreController keystoreController;
  late final AccountsStorageController accountsStorageController;
  late final SubscriptionsController subscriptionsController;
  late final ConnectionController connectionController;
  late final ApprovalController approvalController;
  late final PermissionsController permissionsController;
  late final StreamSubscription _keysStreamSubscription;
  late final StreamSubscription _currentKeyStreamSubscription;
  late final StreamSubscription _currentAccountStreamSubscription;
  late List<KeyStoreEntry> _previousKeys;
  late List<AssetsList> _previousAccounts;
  KeyStoreEntry? _previousKey;
  Transport? _previousTransport;

  Nekoton._();

  static Future<Nekoton> getInstance(Logger? logger) async => _lock.synchronized<Nekoton>(() async {
        nekotonLogger ??= logger;

        if (_instance == null) {
          final instance = Nekoton._();
          await instance._initialize();
          _instance = instance;
        }

        return _instance!;
      });

  Future<void> _keysStreamListener(List<KeyStoreEntry> event) async {
    final addedKeys = [...event]..removeWhere((e) => _previousKeys.contains(e));
    final removedKeys = [..._previousKeys]..removeWhere((e) => event.contains(e));

    for (final key in addedKeys) {
      await accountsStorageController.findExistingAccounts(key.publicKey);
    }

    for (final key in removedKeys) {
      final accounts = accountsStorageController.accounts.where((e) => e.publicKey == key.publicKey);

      for (final account in accounts) {
        await accountsStorageController.removeAccount(account.address);
      }
    }

    _previousKeys = event;
  }

  Future<void> _currentKeyStreamListener(Tuple3<KeyStoreEntry?, List<AssetsList>, Transport> event) async {
    final currentKey = event.item1;
    final currentTransport = event.item3;

    if (_previousKey == currentKey && _previousTransport == currentTransport) {
      return;
    }

    if (currentKey == null) {
      subscriptionsController.clearTonWalletsSubscriptions();
      subscriptionsController.clearTokenWalletsSubscriptions();
      _previousKey = currentKey;
      return;
    }

    final accounts = event.item2.where((e) => e.publicKey == currentKey.publicKey).toList();

    await subscriptionsController.updateCurrentSubscriptions(
      publicKey: currentKey.publicKey,
      accounts: accounts,
    );

    _previousKey = currentKey;
    _previousTransport = currentTransport;
  }

  Future<void> _currentAccountStreamListener(
      Tuple5<KeyStoreEntry?, List<AssetsList>, Transport, List<TonWallet>, List<TokenWallet>> event) async {
    final currentKey = event.item1;
    final currentAccounts = event.item2;

    if (currentKey == null || currentKey != _previousKey || currentAccounts == _previousAccounts) {
      _previousAccounts = currentAccounts;
      return;
    }

    final currentTonWallets = currentAccounts.where((e) => e.publicKey == currentKey.publicKey).map((e) => e.tonWallet);
    final previousTonWallets =
        _previousAccounts.where((e) => e.publicKey == currentKey.publicKey).map((e) => e.tonWallet);

    final addedTonWallets = ([...currentTonWallets]..removeWhere((e) => previousTonWallets.contains(e)));
    final removedTonWallets = ([...previousTonWallets]..removeWhere((e) => currentTonWallets.contains(e)));

    for (final tonWallet in addedTonWallets) {
      await subscriptionsController.subscribeToTonWallet(
        publicKey: currentKey.publicKey,
        tonWalletAsset: tonWallet,
      );
    }

    for (final tonWallet in removedTonWallets) {
      subscriptionsController.removeTonWalletSubscription(tonWallet);
    }

    final networkGroup = event.item3.connectionData.group;

    final currentTokenWallets = currentAccounts
        .where((e) => e.publicKey == currentKey.publicKey)
        .map((e) => Tuple2(e.tonWallet, e.additionalAssets[networkGroup]?.tokenWallets ?? []));
    final previousTokenWallets = _previousAccounts
        .where((e) => e.publicKey == currentKey.publicKey)
        .map((e) => Tuple2(e.tonWallet, e.additionalAssets[networkGroup]?.tokenWallets ?? []));

    final addedTokenWallets = ([...currentTokenWallets]..removeWhere((e) => previousTokenWallets.contains(e)));
    final removedTokenWallets = ([...previousTokenWallets]..removeWhere((e) => currentTokenWallets.contains(e)));

    for (final tokenWalletTuple in addedTokenWallets) {
      for (final tokenWallet in tokenWalletTuple.item2) {
        await subscriptionsController.subscribeToTokenWallet(
          tonWalletAsset: tokenWalletTuple.item1,
          tokenWalletAsset: tokenWallet,
        );
      }
    }

    for (final tokenWalletTuple in removedTokenWallets) {
      for (final tokenWallet in tokenWalletTuple.item2) {
        subscriptionsController.removeTokenWalletSubscription(tokenWallet);
      }
    }

    _previousAccounts = currentAccounts;
  }

  Future<void> _initialize() async {
    connectionController = await ConnectionController.getInstance();
    permissionsController = await PermissionsController.getInstance();
    approvalController = ApprovalController.instance();
    keystoreController = await KeystoreController.getInstance();
    accountsStorageController = await AccountsStorageController.getInstance();
    subscriptionsController = await SubscriptionsController.getInstance();

    _previousKeys = keystoreController.keys;
    _keysStreamSubscription = keystoreController.keysStream.skip(1).listen(_keysStreamListener);

    _currentKeyStreamSubscription = Rx.combineLatest3<KeyStoreEntry?, List<AssetsList>, Transport,
        Tuple3<KeyStoreEntry?, List<AssetsList>, Transport>>(
      keystoreController.currentKeyStream,
      accountsStorageController.accountsStream,
      connectionController.transportStream,
      (a, b, c) => Tuple3(a, b, c),
    ).listen(_currentKeyStreamListener);

    _previousAccounts = accountsStorageController.accounts;
    _currentAccountStreamSubscription = Rx.combineLatest5<KeyStoreEntry?, List<AssetsList>, Transport, List<TonWallet>,
        List<TokenWallet>, Tuple5<KeyStoreEntry?, List<AssetsList>, Transport, List<TonWallet>, List<TokenWallet>>>(
      keystoreController.currentKeyStream,
      accountsStorageController.accountsStream.skip(1),
      connectionController.transportStream,
      subscriptionsController.tonWalletsStream,
      subscriptionsController.tokenWalletsStream,
      (a, b, c, d, e) => Tuple5(a, b, c, d, e),
    ).listen(_currentAccountStreamListener);
  }
}
