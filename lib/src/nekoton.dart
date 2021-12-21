import 'dart:async';

import 'package:collection/collection.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart';

import 'accounts_storage_controller.dart';
import 'approval_controller.dart';
import 'connection_controller.dart';
import 'constants.dart';
import 'core/accounts_storage/models/assets_list.dart';
import 'core/accounts_storage/models/wallet_type.dart';
import 'core/keystore/models/key_store_entry.dart';
import 'core/ton_wallet/find_existing_wallets.dart';
import 'core/ton_wallet/get_ton_wallet_info.dart';
import 'external_accounts_controller.dart';
import 'keystore_controller.dart';
import 'native_library.dart';
import 'permissions_controller.dart';
import 'subscriptions_controller.dart';
import 'transport/gql_transport.dart';
import 'transport/transport.dart';

Logger? nekotonLogger;
late NativeLibrary nativeLibraryInstance;

class Nekoton {
  static Nekoton? _instance;
  static final _lock = Lock();
  static final _keysStreamSubscriptionLock = Lock();
  static final _accountsStreamSubscriptionLock = Lock();
  static final _externalAccountsStreamSubscriptionLock = Lock();
  static final _currentAccountsStreamSubscriptionLock = Lock();
  static final _subscriptionsUpdateStreamSubscriptionLock = Lock();
  static final _accountsPermissionsStreamSubscriptionLock = Lock();
  late final KeystoreController keystoreController;
  late final AccountsStorageController accountsStorageController;
  late final ExternalAccountsController externalAccountsController;
  late final SubscriptionsController subscriptionsController;
  late final ConnectionController connectionController;
  late final ApprovalController approvalController;
  late final PermissionsController permissionsController;
  late final StreamSubscription _keysStreamSubscription;
  late final StreamSubscription _accountsStreamSubscription;
  late final StreamSubscription _externalAccountsStreamSubscription;
  late final StreamSubscription _currentAccountsStreamSubscription;
  late final StreamSubscription _subscriptionsUpdateStreamSubscription;
  late final StreamSubscription _accountsPermissionsStreamSubscription;

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
    _accountsStreamSubscription.cancel();
    _externalAccountsStreamSubscription.cancel();
    _currentAccountsStreamSubscription.cancel();
    _subscriptionsUpdateStreamSubscription.cancel();
    _accountsPermissionsStreamSubscription.cancel();
  }

  Future<void> _keysStreamListener({
    required List<KeyStoreEntry> prev,
    required List<KeyStoreEntry> next,
  }) async {
    final addedKeys = [...next]..removeWhere((e) => prev.contains(e));
    final removedKeys = [...prev]..removeWhere((e) => next.contains(e));

    for (final key in addedKeys) {
      final wallets = await findExistingWallets(
        transport: connectionController.transport as GqlTransport,
        publicKey: key.publicKey,
        workchainId: kDefaultWorkchain,
      );

      final activeWallets = wallets.where((e) => e.contractState.isDeployed || e.contractState.balance != '0');

      for (final activeWallet in activeWallets) {
        final isExists = accountsStorageController.accounts.any((e) => e.address == activeWallet.address);

        if (!isExists) {
          await accountsStorageController.addAccount(
            name: activeWallet.walletType.describe(),
            publicKey: key.publicKey,
            walletType: activeWallet.walletType,
            workchain: kDefaultWorkchain,
          );
        }
      }
    }

    for (final key in removedKeys) {
      final accounts = accountsStorageController.accounts.where((e) => e.publicKey == key.publicKey);

      for (final account in accounts) {
        await accountsStorageController.removeAccount(account.address);
      }
    }
  }

  Future<void> _accountsStreamListener({
    required List<AssetsList> prev,
    required List<AssetsList> next,
  }) async {
    final removedAccounts = [...prev]..removeWhere((e) => next.contains(e));

    for (final account in removedAccounts) {
      final externalAccounts = externalAccountsController.externalAccounts.entries
          .map((e) => e.value.map((el) => Tuple2(e.key, el)))
          .expand((e) => e)
          .where((e) => e.item2 == account.address)
          .toList();

      for (final externalAccount in externalAccounts) {
        await externalAccountsController.removeExternalAccount(
          publicKey: externalAccount.item1,
          address: externalAccount.item2,
        );
      }
    }
  }

  Future<void> _externalAccountsStreamListener({
    required List<String> prev,
    required List<String> next,
  }) async {
    final addedExternalAccounts = [...next]..removeWhere((e) => prev.contains(e));
    final removedExternalAccounts = [...prev]..removeWhere((e) => next.contains(e));

    for (final externalAccount in addedExternalAccounts) {
      final isExists = accountsStorageController.accounts.any((e) => e.address == externalAccount);

      if (!isExists) {
        final tonWalletInfo = await getTonWalletInfo(
          transport: connectionController.transport as GqlTransport,
          address: externalAccount,
        );

        await accountsStorageController.addAccount(
          name: tonWalletInfo.walletType.describe(),
          publicKey: tonWalletInfo.publicKey,
          walletType: tonWalletInfo.walletType,
          workchain: tonWalletInfo.workchain,
        );
      }
    }

    for (final externalAccount in removedExternalAccounts) {
      final account = accountsStorageController.accounts.firstWhereOrNull((e) => e.address == externalAccount);

      if (account != null) {
        final isExists = keystoreController.keys.any((e) => e.publicKey == account.publicKey);

        if (!isExists) {
          await accountsStorageController.removeAccount(account.address);
        }
      }
    }
  }

  Future<void> _currentAccountsStreamListener({
    required Tuple2<KeyStoreEntry?, List<AssetsList>> prev,
    required Tuple2<KeyStoreEntry?, List<AssetsList>> next,
  }) async {
    final currentKey = next.item1;

    if (currentKey == null) {
      await subscriptionsController.clearTonWalletsSubscriptions();
      await subscriptionsController.clearTokenWalletsSubscriptions();
      return;
    }

    final currentTonWallets = next.item2.map((e) => e.tonWallet).toList();
    final previousTonWallets = prev.item2.map((e) => e.tonWallet).toList();

    final addedTonWallets = ([...currentTonWallets]..removeWhere((e) => previousTonWallets.contains(e)));
    final removedTonWallets = ([...previousTonWallets]..removeWhere((e) => currentTonWallets.contains(e)));

    for (final tonWallet in addedTonWallets) {
      await subscriptionsController.subscribeToTonWallet(
        address: tonWallet.address,
        workchain: tonWallet.workchain,
        publicKey: tonWallet.publicKey,
        walletType: tonWallet.contract,
      );
    }

    for (final tonWallet in removedTonWallets) {
      await subscriptionsController.removeTonWalletSubscription(tonWallet.address);
    }

    final networkGroup = connectionController.transport.connectionData.group;

    final currentTokenWallets = next.item2
        .map(
          (e) =>
              e.additionalAssets[networkGroup]?.tokenWallets.map(
                (el) => Tuple2(
                  e.tonWallet.address,
                  el.rootTokenContract,
                ),
              ) ??
              [],
        )
        .expand((e) => e);
    final previousTokenWallets = prev.item2
        .map(
          (e) =>
              e.additionalAssets[networkGroup]?.tokenWallets.map(
                (el) => Tuple2(
                  e.tonWallet.address,
                  el.rootTokenContract,
                ),
              ) ??
              [],
        )
        .expand((e) => e);

    final addedTokenWallets = [...currentTokenWallets]..removeWhere((e) => previousTokenWallets.contains(e));
    final removedTokenWallets = [...previousTokenWallets]..removeWhere((e) => currentTokenWallets.contains(e));

    for (final tokenWallet in addedTokenWallets) {
      await subscriptionsController.subscribeToTokenWallet(
        owner: tokenWallet.item1,
        rootTokenContract: tokenWallet.item2,
      );
    }

    for (final tokenWallet in removedTokenWallets) {
      await subscriptionsController.removeTokenWalletSubscription(
        owner: tokenWallet.item1,
        rootTokenContract: tokenWallet.item2,
      );
    }
  }

  Future<void> _accountsPermissionsStreamListener({
    required List<AssetsList> prev,
    required List<AssetsList> next,
  }) async {
    final removedAccounts = [...prev]..removeWhere((e) => next.contains(e));

    for (final account in removedAccounts) {
      await permissionsController.deletePermissionsForAccount(account.address);
    }
  }

  Future<void> _subscriptionsUpdateStreamListener({
    required Transport prev,
    required Transport next,
  }) async {
    final tonWallets = subscriptionsController.tonWallets
        .map(
          (e) => Tuple4(
            e.address,
            e.workchain,
            e.publicKey,
            e.walletType,
          ),
        )
        .toList();
    final tokenWallets = subscriptionsController.tokenWallets
        .map(
          (e) => Tuple2(
            e.owner,
            e.symbol.rootTokenContract,
          ),
        )
        .toList();

    await subscriptionsController.clearTonWalletsSubscriptions();
    await subscriptionsController.clearTokenWalletsSubscriptions();

    for (final tonWallet in tonWallets) {
      await subscriptionsController.subscribeToTonWallet(
        address: tonWallet.item1,
        workchain: tonWallet.item2,
        publicKey: tonWallet.item3,
        walletType: tonWallet.item4,
      );
    }

    for (final tokenWallet in tokenWallets) {
      await subscriptionsController.subscribeToTokenWallet(
        owner: tokenWallet.item1,
        rootTokenContract: tokenWallet.item2,
      );
    }
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

    keystoreController.keysStream.listen((event) {
      nekotonLogger?.i(event.map((e) => e.publicKey).toList(), 'keysStream');
    });

    accountsStorageController.accountsStream.listen((event) {
      nekotonLogger?.i(event.map((e) => e.address).toList(), 'accountsStream');
    });

    externalAccountsController.externalAccountsStream.listen((event) {
      nekotonLogger?.i(event, 'externalAccountsStream');
    });

    subscriptionsController.tonWalletsStream.listen((event) {
      nekotonLogger?.i(event.map((e) => e.address).toList(), 'tonWalletsStream');
    });

    subscriptionsController.tokenWalletsStream.listen((event) {
      nekotonLogger?.i(event.map((e) => e.address).toList(), 'tokenWalletsStream');
    });

    _keysStreamSubscription =
        keystoreController.keysStream.skip(1).startWith(keystoreController.keys).pairwise().listen(
              (e) => _keysStreamSubscriptionLock.synchronized(
                () {
                  final prev = e.first;
                  final next = e.last;

                  return _keysStreamListener(
                    prev: prev,
                    next: next,
                  );
                },
              ),
            );

    _accountsStreamSubscription = accountsStorageController.accountsStream
        .skip(1)
        .startWith(accountsStorageController.accounts)
        .pairwise()
        .listen(
          (e) => _accountsStreamSubscriptionLock.synchronized(
            () {
              final prev = e.first;
              final next = e.last;

              return _accountsStreamListener(
                prev: prev,
                next: next,
              );
            },
          ),
        );

    _externalAccountsStreamSubscription = externalAccountsController.externalAccountsStream
        .skip(1)
        .startWith(externalAccountsController.externalAccounts)
        .pairwise()
        .listen(
          (e) => _externalAccountsStreamSubscriptionLock.synchronized(
            () {
              final prev = e.first.values.expand((e) => e).toSet().toList();
              final next = e.last.values.expand((e) => e).toSet().toList();

              return _externalAccountsStreamListener(
                prev: prev,
                next: next,
              );
            },
          ),
        );

    _currentAccountsStreamSubscription = Rx.combineLatest3<KeyStoreEntry?, List<AssetsList>, Map<String, List<String>>,
            Tuple2<KeyStoreEntry?, List<AssetsList>>>(
      keystoreController.currentKeyStream,
      accountsStorageController.accountsStream,
      externalAccountsController.externalAccountsStream,
      (a, b, c) {
        final currentKey = a;

        List<AssetsList> internalAccounts = [];
        List<AssetsList> externalAccounts = [];

        if (currentKey != null) {
          final externalAddresses = c[a?.publicKey] ?? [];

          internalAccounts = b.where((e) => e.publicKey == a?.publicKey).toList();
          externalAccounts =
              b.where((e) => e.publicKey != a?.publicKey && externalAddresses.any((el) => el == e.address)).toList();
        }

        final list = [
          ...internalAccounts,
          ...externalAccounts,
        ];

        return Tuple2(currentKey, list);
      },
    ).startWith(const Tuple2(null, [])).pairwise().listen(
          (e) => _currentAccountsStreamSubscriptionLock.synchronized(
            () {
              final prev = e.first;
              final next = e.last;

              return _currentAccountsStreamListener(
                prev: prev,
                next: next,
              );
            },
          ),
        );

    _accountsPermissionsStreamSubscription = accountsStorageController.accountsStream
        .skip(1)
        .startWith(accountsStorageController.accounts)
        .pairwise()
        .listen(
          (e) => _accountsPermissionsStreamSubscriptionLock.synchronized(
            () {
              final prev = e.first;
              final next = e.last;

              return _accountsPermissionsStreamListener(
                prev: prev,
                next: next,
              );
            },
          ),
        );

    _subscriptionsUpdateStreamSubscription =
        connectionController.transportStream.skip(1).startWith(connectionController.transport).pairwise().listen(
              (e) => _subscriptionsUpdateStreamSubscriptionLock.synchronized(
                () {
                  final prev = e.first;
                  final next = e.last;

                  return _subscriptionsUpdateStreamListener(
                    prev: prev,
                    next: next,
                  );
                },
              ),
            );
  }
}
