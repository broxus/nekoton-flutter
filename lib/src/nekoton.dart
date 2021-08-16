import 'dart:async';
import 'dart:ffi';

import 'package:collection/collection.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

import 'core/accounts_storage/accounts_storage.dart';
import 'core/accounts_storage/models/wallet_type.dart';
import 'core/keystore/keystore.dart';
import 'core/models/account_subscription.dart';
import 'core/token_wallet/token_wallet.dart';
import 'core/ton_wallet/ton_wallet.dart';
import 'crypto/models/create_key_input.dart';
import 'crypto/models/export_key_input.dart';
import 'crypto/models/export_key_output.dart';
import 'crypto/models/sign_input.dart';
import 'crypto/models/update_key_input.dart';
import 'models/account_subject.dart';
import 'models/key_subject.dart';
import 'models/subscription_subject.dart';
import 'native_library.dart';

class Nekoton {
  static const _workchain = 0;
  static const _networkGroup = 'mainnet';
  static Nekoton? _instance;
  static final _lock = Lock();
  final _nativeLibrary = NativeLibrary.instance();
  final Logger? _logger;
  late final Keystore _keystore;
  late final AccountsStorage _accountsStorage;
  final _keysSubject = BehaviorSubject<List<KeySubject>>.seeded([]);
  final _accountsSubject = BehaviorSubject<List<AccountSubject>>.seeded([]);
  final _subscriptionsSubject = BehaviorSubject<List<SubscriptionSubject>>.seeded([]);
  final _currentKeySubject = BehaviorSubject<KeySubject?>.seeded(null);

  Nekoton._(this._logger);

  static Future<Nekoton> getInstance({
    Logger? logger,
    String? currentPublicKey,
  }) async =>
      _lock.synchronized<Nekoton>(() async {
        if (_instance == null) {
          final instance = Nekoton._(logger);
          await instance._initialize(
            currentPublicKey: currentPublicKey,
          );
          _instance = instance;
        }

        return _instance!;
      });

  Stream<List<KeySubject>> get keysStream => _keysSubject.stream.distinct();

  Stream<List<AccountSubject>> get accountsStream => _accountsSubject.stream.distinct();

  Stream<List<SubscriptionSubject>> get subscriptionsStream => _subscriptionsSubject.stream.distinct();

  Stream<KeySubject?> get currentKeyStream => _currentKeySubject.stream.distinct();

  Stream<bool> get keysPresenceStream => _keysSubject.stream
      .transform<bool>(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data.isNotEmpty),
        ),
      )
      .distinct();

  Stream<bool> get accountsPresenceStream => _accountsSubject.stream
      .transform<bool>(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data.isNotEmpty),
        ),
      )
      .distinct();

  Stream<bool> get subscriptionsPresenceStream => _subscriptionsSubject.stream
      .transform<bool>(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data.isNotEmpty),
        ),
      )
      .distinct();

  List<KeySubject> get keys => _keysSubject.value;

  List<AccountSubject> get accounts => _accountsSubject.value;

  List<SubscriptionSubject> get subscriptions => _subscriptionsSubject.value;

  KeySubject? get currentKey => _currentKeySubject.value;

  Future<void> setCurrentKey(KeySubject? currentKey) async {
    _currentKeySubject.add(currentKey);
    await _updateSubscriptions(currentKey);
  }

  Future<KeySubject> addKey(CreateKeyInput createKeyInput) async {
    final entry = await _keystore.addKey(createKeyInput);
    final subject = KeySubject(entry);

    final keys = [..._keysSubject.value];

    keys
      ..removeWhere((e) => e.value == entry)
      ..add(subject)
      ..sort(_sortKeys);

    _keysSubject.add(keys);

    if (currentKey == null) {
      await setCurrentKey(_keysSubject.value.firstOrNull);
    }

    return subject;
  }

  Future<KeySubject> updateKey(UpdateKeyInput updateKeyInput) async {
    final entry = await _keystore.updateKey(updateKeyInput);
    final subject = _keysSubject.value.firstWhere((e) => e.value.publicKey == entry.publicKey);

    subject.add(entry);

    return subject;
  }

  Future<ExportKeyOutput> exportKey(ExportKeyInput exportKeyInput) async => _keystore.exportKey(exportKeyInput);

  Future<bool> checkKeyPassword(SignInput signInput) async => _keystore.checkKeyPassword(signInput);

  Future<KeySubject?> removeKey(String publicKey) async {
    final key = _keysSubject.value.firstWhereOrNull((e) => e.value.publicKey == publicKey);

    if (key == null) {
      return null;
    }

    if (currentKey == key) {
      final newCurrentKey = _keysSubject.value.firstWhereOrNull((e) => e != key);
      await setCurrentKey(newCurrentKey);
    }

    final accounts = _accountsSubject.value.where((e) => e.value.publicKey == key.value.publicKey);

    for (final account in accounts) {
      await removeAccount(account.value.address);
    }

    final keys = [..._keysSubject.value];

    keys
      ..remove(key)
      ..sort(_sortKeys);

    _keysSubject.add(keys);

    await _keystore.removeKey(key.value.publicKey);

    final derivedKeys = _keysSubject.value.where((e) => e.value.masterKey == key.value.publicKey);

    for (final key in derivedKeys) {
      await removeKey(key.value.publicKey);
    }

    return key;
  }

  Future<void> clearKeystore() async {
    await setCurrentKey(null);

    final keys = [..._keysSubject.value];

    for (final key in keys) {
      final accounts = _accountsSubject.value.where((e) => e.value.publicKey == key.value.publicKey);

      for (final account in accounts) {
        await removeAccount(account.value.address);
      }
    }

    _keysSubject.add([]);

    await _keystore.clear();
  }

  Future<AccountSubject> addAccount({
    required String name,
    required String publicKey,
    required WalletType walletType,
  }) async {
    final assets = await _accountsStorage.addAccount(
      name: name,
      publicKey: publicKey,
      walletType: walletType,
      workchain: _workchain,
    );
    final subject = AccountSubject(assets);

    final accounts = [..._accountsSubject.value];

    accounts
      ..add(subject)
      ..sort(_sortAccounts);

    _accountsSubject.add(accounts);

    await _addSubscription(subject);

    return subject;
  }

  Future<AccountSubject> renameAccount({
    required String address,
    required String name,
  }) async {
    final assets = await _accountsStorage.renameAccount(
      address: address,
      name: name,
    );
    final subject = _accountsSubject.value.firstWhere((e) => e.value.address == assets.tonWallet.address);
    final account = subject.value.copyWith(name: assets.name);

    subject.add(account);

    return subject;
  }

  Future<AccountSubject?> removeAccount(String address) async {
    final subject = _accountsSubject.value.firstWhereOrNull((e) => e.value.address == address);

    if (subject == null) {
      return null;
    }

    final accounts = [..._accountsSubject.value];

    accounts
      ..remove(subject)
      ..sort(_sortAccounts);

    _accountsSubject.add(accounts);

    await _accountsStorage.removeAccount(subject.value.address);

    await _removeSubscription(subject);

    return subject;
  }

  Future<AccountSubject> addTokenWallet({
    required String address,
    required String rootTokenContract,
  }) async {
    final subject = _accountsSubject.value.firstWhere((e) => e.value.address == address);
    final assets = await _accountsStorage.addTokenWallet(
      address: subject.value.address,
      rootTokenContract: rootTokenContract,
      networkGroup: _networkGroup,
    );
    subject.add(assets);

    await _addTokenWalletToSubscription(
      account: subject,
      rootTokenContract: rootTokenContract,
    );

    return subject;
  }

  Future<AccountSubject> removeTokenWallet({
    required String address,
    required String rootTokenContract,
  }) async {
    final subject = _accountsSubject.value.firstWhere((e) => e.value.address == address);
    final assets = await _accountsStorage.removeTokenWallet(
      address: subject.value.address,
      rootTokenContract: rootTokenContract,
      networkGroup: _networkGroup,
    );
    subject.add(assets);

    await _removeTokenWalletFromSubscription(
      account: subject,
      rootTokenContract: rootTokenContract,
    );

    return subject;
  }

  Future<void> clearAccountsStorage() async {
    _accountsSubject.add([]);

    await _accountsStorage.clear();

    await _clearSubscriptions();
  }

  Future<void> _updateSubscriptions(KeySubject? currentKey) async {
    try {
      final subscriptions = [..._subscriptionsSubject.value];

      _subscriptionsSubject.add([]);

      for (final subscription in subscriptions) {
        await _unsubscribe(subscription);
      }

      if (currentKey == null) {
        return;
      }

      subscriptions.clear();

      final accounts = _accountsSubject.value.where((e) => e.value.publicKey == currentKey.value.publicKey);

      for (final account in accounts) {
        final subject = await _subscribe(
          key: currentKey,
          account: account,
        );

        subscriptions.add(subject);
      }

      subscriptions.sort(_sortSubscriptions);

      _subscriptionsSubject.add(subscriptions);
    } catch (err, st) {
      _logger?.e(err, err, st);
    }
  }

  Future<void> _addSubscription(AccountSubject account) async {
    if (account.value.publicKey != currentKey?.value.publicKey) {
      return;
    }

    final keySubject = _keysSubject.value.firstWhere((e) => e.value.publicKey == account.value.publicKey);

    final subject = await _subscribe(
      key: keySubject,
      account: account,
    );

    final subscriptions = [..._subscriptionsSubject.value];

    subscriptions
      ..add(subject)
      ..sort(_sortSubscriptions);

    _subscriptionsSubject.add(subscriptions);
  }

  Future<void> _removeSubscription(AccountSubject account) async {
    if (account.value.publicKey != currentKey?.value.publicKey) {
      return;
    }

    final subject = _subscriptionsSubject.value.firstWhereOrNull((e) => e.value.address == account.value.address);

    if (subject == null) {
      return;
    }

    final subscriptions = [..._subscriptionsSubject.value];

    subscriptions
      ..remove(subject)
      ..sort(_sortSubscriptions);

    _subscriptionsSubject.add(subscriptions);

    await _unsubscribe(subject);
  }

  Future<void> _addTokenWalletToSubscription({
    required AccountSubject account,
    required String rootTokenContract,
  }) async {
    if (account.value.publicKey != currentKey?.value.publicKey) {
      return;
    }

    final subject = _subscriptionsSubject.value.firstWhereOrNull((e) => e.value.address == account.value.address);
    if (subject == null) {
      return;
    }
    final tokenWallets = [...subject.value.tokenWallets];

    try {
      final tokenWallet = await tokenWalletSubscribe(
        tonWallet: subject.value.tonWallet,
        rootTokenContract: rootTokenContract,
      );
      tokenWallets
        ..add(tokenWallet)
        ..sort(_sortTokenWallets);

      final subscription = subject.value.copyWith(tokenWallets: tokenWallets);
      subject.add(subscription);
    } catch (err, st) {
      _logger?.e(err, err, st);
      await removeTokenWallet(
        address: account.value.address,
        rootTokenContract: rootTokenContract,
      );
    }
  }

  Future<void> _removeTokenWalletFromSubscription({
    required AccountSubject account,
    required String rootTokenContract,
  }) async {
    if (account.value.publicKey != currentKey?.value.publicKey) {
      return;
    }

    final subject = _subscriptionsSubject.value.firstWhereOrNull((e) => e.value.address == account.value.address);

    if (subject == null) {
      return;
    }

    final tokenWallets = [...subject.value.tokenWallets];
    final tokenWallet = tokenWallets.firstWhereOrNull((e) => e.symbol.rootTokenContract == rootTokenContract);

    if (tokenWallet == null) {
      return;
    }

    tokenWallets
      ..remove(tokenWallet)
      ..sort(_sortTokenWallets);
    await tokenWalletUnsubscribe(tokenWallet);

    final subscription = subject.value.copyWith(tokenWallets: tokenWallets);
    subject.add(subscription);
  }

  Future<void> _clearSubscriptions() async {
    final subscriptions = [..._subscriptionsSubject.value];

    _subscriptionsSubject.add([]);

    for (final subscription in subscriptions) {
      await _unsubscribe(subscription);
    }
  }

  Future<SubscriptionSubject> _subscribe({
    required KeySubject key,
    required AccountSubject account,
  }) async {
    try {
      final tonWallet = await tonWalletSubscribe(
        keystore: _keystore,
        workchain: _workchain,
        entry: key.value,
        walletType: account.value.tonWallet.contract,
      );

      final tokenWallets = <TokenWallet>[];
      final tokenWalletAssets = [...account.value.additionalAssets.entries.firstOrNull?.value.tokenWallets ?? []];
      for (final tokenWalletAsset in tokenWalletAssets) {
        try {
          final tokenWallet = await tokenWalletSubscribe(
            tonWallet: tonWallet,
            rootTokenContract: tokenWalletAsset.rootTokenContract,
          );
          tokenWallets.add(tokenWallet);
        } catch (err, st) {
          _logger?.e(err, err, st);
          await removeTokenWallet(
            address: account.value.address,
            rootTokenContract: tokenWalletAsset.rootTokenContract,
          );
        }
      }

      final subscription = AccountSubscription(
        accountSubject: account,
        tonWallet: tonWallet,
        tokenWallets: tokenWallets,
      );
      final subject = SubscriptionSubject(subscription);

      return subject;
    } catch (err, st) {
      _logger?.e(err, err, st);
      await removeAccount(account.value.address);
      rethrow;
    }
  }

  Future<void> _unsubscribe(SubscriptionSubject subscription) async {
    try {
      final tonWallet = subscription.value.tonWallet;
      await tonWalletUnsubscribe(tonWallet);

      final tokenWallets = subscription.value.tokenWallets;
      for (final tokenWallet in tokenWallets) {
        await tokenWalletUnsubscribe(tokenWallet);
      }
    } catch (err, st) {
      _logger?.e(err, err, st);
    }
  }

  Future<void> _initialize({
    String? currentPublicKey,
  }) async {
    _nativeLibrary.bindings.store_post_cobject(Pointer.fromAddress(NativeApi.postCObject.address));

    _keystore = await Keystore.getInstance(logger: _logger);
    _accountsStorage = await AccountsStorage.getInstance(logger: _logger);

    final entries = await _keystore.entries;

    _keysSubject.add([
      ..._keysSubject.value,
      ...entries.map((e) => KeySubject(e)).toList()..sort(_sortKeys),
    ]);

    final assets = await _accountsStorage.accounts;

    _accountsSubject.add([
      ..._accountsSubject.value,
      ...assets.map((e) => AccountSubject(e)).toList()..sort(_sortAccounts),
    ]);

    final currentKey = keys.firstWhereOrNull((e) => e.value.publicKey == currentPublicKey);

    await setCurrentKey(currentKey ?? keys.firstOrNull);
  }

  int _sortKeys(KeySubject a, KeySubject b) => b.value.publicKey.compareTo(a.value.publicKey);

  int _sortAccounts(AccountSubject a, AccountSubject b) => b.value.address.compareTo(a.value.address);

  int _sortSubscriptions(SubscriptionSubject a, SubscriptionSubject b) =>
      b.value.walletType.toInt().compareTo(a.value.walletType.toInt());

  int _sortTokenWallets(TokenWallet a, TokenWallet b) => b.symbol.name.compareTo(a.symbol.name);
}
