import 'dart:async';

import 'package:collection/collection.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart';

import 'accounts_storage_controller.dart';
import 'approval_controller.dart';
import 'connection_controller.dart';
import 'core/accounts_storage/models/assets_list.dart';
import 'core/keystore/models/key_store_entry.dart';
import 'external_accounts_controller.dart';
import 'keystore_controller.dart';
import 'native_library.dart';
import 'permissions_controller.dart';
import 'subscriptions_controller.dart';
import 'transport/transport.dart';

Logger? nekotonLogger;
late NativeLibrary nativeLibraryInstance;

class Nekoton {
  static Nekoton? _instance;
  static final _lock = Lock();
  static final _keysStreamSubscriptionLock = Lock();
  static final _accountsStreamSubscriptionLock = Lock();
  static final _externalAccountsStreamSubscriptionLock = Lock();
  static final _accountsPermissionsStreamSubscriptionLock = Lock();
  static final _subscriptionsUpdateStreamSubscriptionLock = Lock();
  late final KeystoreController keystoreController;
  late final AccountsStorageController accountsStorageController;
  late final ExternalAccountsController externalAccountsController;
  late final SubscriptionsController subscriptionsController;
  late final ConnectionController connectionController;
  late final ApprovalController approvalController;
  late final PermissionsController permissionsController;
  late final StreamSubscription _keysStreamSubscription;
  late final StreamSubscription _subscriptionsUpdateStreamSubscription;
  late final StreamSubscription _accountsStreamSubscription;
  late final StreamSubscription _externalAccountsStreamSubscription;
  late final StreamSubscription _accountsPermissionsStreamSubscription;
  late List<KeyStoreEntry> _previousKeys;
  late List<AssetsList> _previousAccounts;
  List<AssetsList> _previousAssetsLists = [];

  Nekoton._();

  static Future<Nekoton> getInstance({
    Logger? logger,
  }) =>
      _lock.synchronized<Nekoton>(() async {
        nekotonLogger ??= logger;

        if (_instance == null) {
          final instance = Nekoton._();
          await instance._initialize();
          _instance = instance;
        }

        return _instance!;
      });

  Future<void> dispose() async {
    _keysStreamSubscription.cancel();
    _subscriptionsUpdateStreamSubscription.cancel();
    _accountsStreamSubscription.cancel();
    _accountsPermissionsStreamSubscription.cancel();
    _externalAccountsStreamSubscription.cancel();
  }

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

      await externalAccountsController.removeExternalAccounts(key.publicKey);
    }

    _previousKeys = event;
  }

  Future<void> _accountsStreamListener(Tuple2<KeyStoreEntry?, List<AssetsList>> event) async {
    final currentKey = event.item1;
    final currentAccounts = event.item2;

    if (currentKey == null) {
      _previousAccounts = currentAccounts;
      return;
    }

    final currentTonWallets = currentAccounts.where((e) => e.publicKey == currentKey.publicKey).map((e) => e.tonWallet);
    final previousTonWallets =
        _previousAccounts.where((e) => e.publicKey == currentKey.publicKey).map((e) => e.tonWallet);

    final addedTonWallets = ([...currentTonWallets]..removeWhere((e) => previousTonWallets.contains(e)));
    final removedTonWallets = ([...previousTonWallets]..removeWhere((e) => currentTonWallets.contains(e)));

    for (final tonWallet in addedTonWallets) {
      if (subscriptionsController.tonWallets.firstWhereOrNull((e) => e.address == tonWallet.address) != null) {
        continue;
      }

      await subscriptionsController.subscribeToTonWallet(
        publicKey: currentKey.publicKey,
        tonWalletAsset: tonWallet,
      );
    }

    for (final tonWallet in removedTonWallets) {
      await subscriptionsController.removeTonWalletSubscription(tonWallet.address);
    }

    final networkGroup = connectionController.transport.connectionData.group;

    final currentTokenWallets = currentAccounts
        .where((e) => e.publicKey == currentKey.publicKey)
        .map((el) => el.additionalAssets[networkGroup]?.tokenWallets.map((e) => Tuple2(el.tonWallet, e)) ?? [])
        .expand((e) => e);
    final previousTokenWallets = _previousAccounts
        .where((e) => e.publicKey == currentKey.publicKey)
        .map((el) => el.additionalAssets[networkGroup]?.tokenWallets.map((e) => Tuple2(el.tonWallet, e)) ?? [])
        .expand((e) => e);

    final addedTokenWallets = ([...currentTokenWallets]..removeWhere((e) => previousTokenWallets.contains(e)));
    final removedTokenWallets = ([...previousTokenWallets]..removeWhere((e) => currentTokenWallets.contains(e)));

    for (final tokenWallet in addedTokenWallets) {
      if (subscriptionsController.tokenWallets.firstWhereOrNull(
            (e) =>
                e.owner == tokenWallet.item1.address &&
                e.symbol.rootTokenContract == tokenWallet.item2.rootTokenContract,
          ) !=
          null) {
        continue;
      }

      await subscriptionsController.subscribeToTokenWallet(
        tonWalletAsset: tokenWallet.item1,
        tokenWalletAsset: tokenWallet.item2,
      );
    }

    for (final tokenWallet in removedTokenWallets) {
      await subscriptionsController.removeTokenWalletSubscription(
        tonWalletAsset: tokenWallet.item1,
        tokenWalletAsset: tokenWallet.item2,
      );
    }

    _previousAccounts = currentAccounts;
  }

  Future<void> _externalAccountsStreamListener(Tuple2<KeyStoreEntry?, Map<String, List<AssetsList>>> event) async {
    final currentKey = event.item1;
    final currentAssetsLists = [...event.item2[currentKey?.publicKey] ?? <AssetsList>[]];

    if (currentKey == null) {
      _previousAssetsLists = currentAssetsLists;
      return;
    }

    for (final externalAccount in _previousAssetsLists) {
      await subscriptionsController.removeTonWalletSubscription(externalAccount.address);
    }

    for (final externalAccount in currentAssetsLists) {
      await subscriptionsController.subscribeByAddressToTonWallet(externalAccount.address);
    }

    _previousAssetsLists = currentAssetsLists;
  }

  Future<void> _accountsPermissionsStreamListener(Tuple2<KeyStoreEntry?, List<AssetsList>> event) async {
    final currentKey = event.item1;
    final currentAccounts = event.item2;

    if (currentKey == null) {
      _previousAccounts = currentAccounts;
      return;
    }

    final removedAccounts = ([..._previousAccounts]..removeWhere((e) => currentAccounts.contains(e)));

    for (final account in removedAccounts) {
      await permissionsController.deletePermissionsForAccount(account.address);
    }

    _previousAccounts = currentAccounts;
  }

  Future<void> _subscriptionsUpdateStreamListener(KeyStoreEntry? event) async {
    final currentKey = event;

    if (currentKey == null) {
      await subscriptionsController.clearTonWalletsSubscriptions();
      await subscriptionsController.clearTokenWalletsSubscriptions();
      return;
    }

    final accounts = accountsStorageController.accounts.where((e) => e.publicKey == currentKey.publicKey).toList();

    await subscriptionsController.updateCurrentSubscriptions(
      publicKey: currentKey.publicKey,
      accounts: accounts,
    );
  }

  Future<void> _initialize() async {
    nativeLibraryInstance = await NativeLibrary.getInstance();

    connectionController = await ConnectionController.getInstance();
    permissionsController = await PermissionsController.getInstance();
    approvalController = ApprovalController.instance();
    keystoreController = await KeystoreController.getInstance();
    accountsStorageController = await AccountsStorageController.getInstance();
    externalAccountsController = await ExternalAccountsController.getInstance();
    subscriptionsController = await SubscriptionsController.getInstance();

    _previousKeys = keystoreController.keys;
    _keysStreamSubscription = keystoreController.keysStream
        .skip(1)
        .listen((e) => _keysStreamSubscriptionLock.synchronized(() => _keysStreamListener(e)));

    _previousAccounts = accountsStorageController.accounts;
    _accountsStreamSubscription =
        Rx.combineLatest2<KeyStoreEntry?, List<AssetsList>, Tuple2<KeyStoreEntry?, List<AssetsList>>>(
      keystoreController.currentKeyStream,
      accountsStorageController.accountsStream.skip(1),
      (a, b) => Tuple2(a, b),
    ).listen((e) => _accountsStreamSubscriptionLock.synchronized(() => _accountsStreamListener(e)));

    _externalAccountsStreamSubscription = Rx.combineLatest2<KeyStoreEntry?, Map<String, List<AssetsList>>,
        Tuple2<KeyStoreEntry?, Map<String, List<AssetsList>>>>(
      keystoreController.currentKeyStream,
      externalAccountsController.externalAccountsStream,
      (a, b) => Tuple2(a, b),
    ).listen((e) => _externalAccountsStreamSubscriptionLock.synchronized(() => _externalAccountsStreamListener(e)));

    _accountsPermissionsStreamSubscription =
        Rx.combineLatest2<KeyStoreEntry?, List<AssetsList>, Tuple2<KeyStoreEntry?, List<AssetsList>>>(
      keystoreController.currentKeyStream,
      accountsStorageController.accountsStream.skip(1),
      (a, b) => Tuple2(a, b),
    ).listen(
      (e) => _accountsPermissionsStreamSubscriptionLock.synchronized(() => _accountsPermissionsStreamListener(e)),
    );

    _subscriptionsUpdateStreamSubscription = Rx.combineLatest2<KeyStoreEntry?, Transport, KeyStoreEntry?>(
      keystoreController.currentKeyStream,
      connectionController.transportStream,
      (a, b) => a,
    ).listen(
      (e) => _subscriptionsUpdateStreamSubscriptionLock.synchronized(() => _subscriptionsUpdateStreamListener(e)),
    );
  }
}
