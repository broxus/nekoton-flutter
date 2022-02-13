import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../constants.dart';
import '../../core/keystore/keystore.dart';
import '../../crypto/models/sign_input.dart';
import '../../ffi_utils.dart';
import '../../nekoton.dart';
import '../../transport/gql_transport.dart';
import '../accounts_storage/models/wallet_type.dart';
import '../models/contract_state.dart';
import '../models/expiration.dart';
import '../models/native_unsigned_message.dart';
import '../models/on_message_expired_payload.dart';
import '../models/on_message_sent_payload.dart';
import '../models/on_state_changed_payload.dart';
import '../models/pending_transaction.dart';
import '../models/polling_method.dart';
import '../models/subscription_handler_message.dart';
import '../models/transaction.dart';
import '../models/transaction_id.dart';
import '../models/unsigned_message.dart';
import 'models/existing_wallet_info.dart';
import 'models/multisig_pending_transaction.dart';
import 'models/native_ton_wallet.dart';
import 'models/on_ton_wallet_transactions_found_payload.dart';
import 'models/ton_wallet_details.dart';
import 'models/ton_wallet_transaction_with_data.dart';

class TonWallet {
  final _receivePort = ReceivePort();
  late final GqlTransport _transport;
  late final Keystore _keystore;
  late final NativeTonWallet _nativeTonWallet;
  late final StreamSubscription _subscription;
  late final StreamSubscription _onMessageSentSubscription;
  late final StreamSubscription _onMessageExpiredSubscription;
  late final StreamSubscription _onTransactionsFoundSubscription;
  late final Timer _timer;
  late final int workchain;
  late final String address;
  late final String publicKey;
  late final WalletType walletType;
  late final TonWalletDetails details;
  final _onMessageSentSubject = PublishSubject<OnMessageSentPayload>();
  final _onMessageExpiredSubject = PublishSubject<OnMessageExpiredPayload>();
  final _onStateChangedSubject = PublishSubject<OnStateChangedPayload>();
  final _onTransactionsFoundSubject = PublishSubject<OnTonWalletTransactionsFoundPayload>();
  final _transactionsSubject = BehaviorSubject<List<TonWalletTransactionWithData>>.seeded([]);
  final _pendingTransactionsSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);
  final _expiredTransactionsSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);

  TonWallet._();

  static Future<TonWallet> subscribe({
    required GqlTransport transport,
    required int workchain,
    required String publicKey,
    required WalletType walletType,
  }) async {
    final tonWallet = TonWallet._();
    await tonWallet._initialize(
      transport: transport,
      workchain: workchain,
      publicKey: publicKey,
      walletType: walletType,
    );
    return tonWallet;
  }

  static Future<TonWallet> subscribeByAddress({
    required GqlTransport transport,
    required String address,
  }) async {
    final tonWallet = TonWallet._();
    await tonWallet._initializeByAddress(
      transport: transport,
      address: address,
    );
    return tonWallet;
  }

  static Future<TonWallet> subscribeByExisting({
    required GqlTransport transport,
    required ExistingWalletInfo existingWalletInfo,
  }) async {
    final tonWallet = TonWallet._();
    await tonWallet._initializeByExisting(
      transport: transport,
      existingWalletInfo: existingWalletInfo,
    );
    return tonWallet;
  }

  Stream<OnMessageSentPayload> get onMessageSentStream => _onMessageSentSubject.stream;

  Stream<OnMessageExpiredPayload> get onMessageExpiredStream => _onMessageExpiredSubject.stream;

  Stream<OnStateChangedPayload> get onStateChangedStream => _onStateChangedSubject.stream;

  Stream<OnTonWalletTransactionsFoundPayload> get onTransactionsFoundStream => _onTransactionsFoundSubject.stream;

  Stream<List<TonWalletTransactionWithData>> get transactionsStream => _transactionsSubject.stream;

  Stream<List<PendingTransaction>> get pendingTransactionsStream => _pendingTransactionsSubject.stream;

  Stream<List<PendingTransaction>> get expiredTransactionsStream => _expiredTransactionsSubject.stream;

  Future<int> get _workchain async {
    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_ton_wallet_workchain(
          port,
          ptr,
        ),
      ),
    );

    return result;
  }

  Future<String> get _address async {
    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_ton_wallet_address(
          port,
          ptr,
        ),
      ),
    );
    final address = cStringToDart(result);

    return address;
  }

  Future<String> get _publicKey async {
    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_ton_wallet_public_key(
          port,
          ptr,
        ),
      ),
    );
    final publicKey = cStringToDart(result);

    return publicKey;
  }

  Future<WalletType> get _walletType async {
    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_ton_wallet_wallet_type(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final walletType = WalletType.fromJson(json);

    return walletType;
  }

  Future<ContractState> get contractState async {
    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_ton_wallet_contract_state(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final contractState = ContractState.fromJson(json);

    return contractState;
  }

  Future<List<PendingTransaction>> get pendingTransactions async {
    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_ton_wallet_pending_transactions(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final jsonList = json.cast<Map<String, dynamic>>();
    final pendingTransactions = jsonList.map((e) => PendingTransaction.fromJson(e)).toList();

    return pendingTransactions;
  }

  Future<PollingMethod> get pollingMethod async {
    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_ton_wallet_polling_method(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string);
    final pollingMethod = PollingMethod.values.firstWhere((e) => describeEnum(e) == json);

    return pollingMethod;
  }

  Future<TonWalletDetails> get _details async {
    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_ton_wallet_details(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final details = TonWalletDetails.fromJson(json);

    return details;
  }

  Future<List<MultisigPendingTransaction>> get unconfirmedTransactions async {
    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_ton_wallet_unconfirmed_transactions(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final jsonList = json.cast<Map<String, dynamic>>();
    final pendingTransactions = jsonList.map((e) => MultisigPendingTransaction.fromJson(e)).toList();

    return pendingTransactions;
  }

  Future<List<String>?> get custodians async {
    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_ton_wallet_custodians(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>?;
    final custodians = json?.cast<String>();

    return custodians;
  }

  Future<UnsignedMessage> prepareDeploy(Expiration expiration) async {
    final expirationStr = jsonEncode(expiration);

    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.ton_wallet_prepare_deploy(
          port,
          ptr,
          expirationStr.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );

    final ptr = Pointer.fromAddress(result).cast<Void>();
    final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
    final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareDeployWithMultipleOwners({
    required Expiration expiration,
    required List<String> custodians,
    required int reqConfirms,
  }) async {
    final expirationStr = jsonEncode(expiration);
    final custodiansStr = jsonEncode(custodians);

    final result = await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.ton_wallet_prepare_deploy_with_multiple_owners(
          port,
          ptr,
          expirationStr.toNativeUtf8().cast<Int8>(),
          custodiansStr.toNativeUtf8().cast<Int8>(),
          reqConfirms,
        ),
      ),
    );

    final ptr = Pointer.fromAddress(result).cast<Void>();
    final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
    final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareTransfer({
    required String publicKey,
    required String destination,
    required int amount,
    String? body,
    bool isComment = true,
    required Expiration expiration,
  }) async {
    final expirationStr = jsonEncode(expiration);

    final result = await _nativeTonWallet.use(
      (ptr) => _transport.nativeGqlTransport.use(
        (nativeGqlTransportPtr) => proceedAsync(
          (port) => nativeLibraryInstance.bindings.ton_wallet_prepare_transfer(
            port,
            ptr,
            nativeGqlTransportPtr,
            publicKey.toNativeUtf8().cast<Int8>(),
            destination.toNativeUtf8().cast<Int8>(),
            amount,
            body?.toNativeUtf8().cast<Int8>() ?? Pointer.fromAddress(0).cast<Int8>(),
            isComment ? 1 : 0,
            expirationStr.toNativeUtf8().cast<Int8>(),
          ),
        ),
      ),
    );

    final ptr = Pointer.fromAddress(result).cast<Void>();
    final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
    final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareConfirmTransaction({
    required String publicKey,
    required String transactionId,
    required Expiration expiration,
  }) async {
    final expirationStr = jsonEncode(expiration);

    final result = await _nativeTonWallet.use(
      (ptr) => _transport.nativeGqlTransport.use(
        (nativeGqlTransportPtr) => proceedAsync(
          (port) => nativeLibraryInstance.bindings.ton_wallet_prepare_confirm_transaction(
            port,
            ptr,
            nativeGqlTransportPtr,
            publicKey.toNativeUtf8().cast<Int8>(),
            transactionId.toNativeUtf8().cast<Int8>(),
            expirationStr.toNativeUtf8().cast<Int8>(),
          ),
        ),
      ),
    );

    final ptr = Pointer.fromAddress(result).cast<Void>();
    final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
    final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

    return unsignedMessage;
  }

  Future<String> estimateFees(UnsignedMessage message) async {
    final result = await _nativeTonWallet.use(
      (ptr) => message.nativeUnsignedMessage.use(
        (nativeUnsignedMessagePtr) => proceedAsync(
          (port) => nativeLibraryInstance.bindings.ton_wallet_estimate_fees(
            port,
            ptr,
            nativeUnsignedMessagePtr,
          ),
        ),
      ),
    );

    final fees = cStringToDart(result);

    return fees;
  }

  Future<PendingTransaction> send({
    required UnsignedMessage message,
    required SignInput signInput,
  }) async {
    final signInputStr = signInput.when(
      derivedKeySignParams: (derivedKeySignParams) => jsonEncode(derivedKeySignParams),
      encryptedKeyPassword: (encryptedKeyPassword) => jsonEncode(encryptedKeyPassword),
    );

    final currentBlockId = await _transport.getLatestBlockId(address);

    final result = await _nativeTonWallet.use(
      (ptr) => _keystore.nativeKeystore.use(
        (nativeKeystorePtr) => message.nativeUnsignedMessage.use(
          (nativeUnsignedMessagePtr) => proceedAsync(
            (port) => nativeLibraryInstance.bindings.ton_wallet_send(
              port,
              ptr,
              nativeKeystorePtr,
              nativeUnsignedMessagePtr,
              signInputStr.toNativeUtf8().cast<Int8>(),
            ),
          ),
        ),
      ),
    );
    await message.nativeUnsignedMessage.free();

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final pendingTransaction = PendingTransaction.fromJson(json);

    final pending = [
      pendingTransaction,
      ..._pendingTransactionsSubject.value,
    ];

    _pendingTransactionsSubject.add(pending);

    _internalRefresh(currentBlockId);

    return pendingTransaction;
  }

  Future<void> refresh() => _nativeTonWallet.use(
        (ptr) => proceedAsync(
          (port) => nativeLibraryInstance.bindings.ton_wallet_refresh(
            port,
            ptr,
          ),
        ),
      );

  Future<void> preloadTransactions(TransactionId from) async {
    final fromStr = jsonEncode(from);

    await _nativeTonWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.ton_wallet_preload_transactions(
          port,
          ptr,
          fromStr.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );
  }

  Future<Transaction> waitForTransaction(PendingTransaction pendingTransaction) async => _onMessageSentSubject.stream
      .firstWhere((e) => e.pendingTransaction == pendingTransaction)
      .then((v) => v.transaction!);

  Future<void> free() async {
    _timer.cancel();

    _subscription.cancel();
    _onMessageSentSubscription.cancel();
    _onMessageExpiredSubscription.cancel();
    _onTransactionsFoundSubscription.cancel();

    _onMessageSentSubject.close();
    _onMessageExpiredSubject.close();
    _onStateChangedSubject.close();
    _onTransactionsFoundSubject.close();
    _transactionsSubject.close();
    _pendingTransactionsSubject.close();
    _expiredTransactionsSubject.close();

    _receivePort.close();

    await _nativeTonWallet.free();
  }

  Future<void> _handleBlock(String id) => _nativeTonWallet.use(
        (ptr) => _transport.nativeGqlTransport.use(
          (nativeGqlTransportPtr) => proceedAsync(
            (port) => nativeLibraryInstance.bindings.ton_wallet_handle_block(
              port,
              ptr,
              nativeGqlTransportPtr,
              id.toNativeUtf8().cast<Int8>(),
            ),
          ),
        ),
      );

  Future<void> _internalRefresh(String currentBlockId) async {
    for (var i = 0; 0 < 10; i++) {
      try {
        if (_nativeTonWallet.isNull) break;

        final nextBlockId = await _transport.waitForNextBlockId(
          currentBlockId: currentBlockId,
          address: address,
        );

        await _handleBlock(nextBlockId);
        await refresh();

        if (await pollingMethod == PollingMethod.manual) break;
      } catch (err, st) {
        logger?.e(err, err, st);
        break;
      }
    }
  }

  Future<void> _initialize({
    required GqlTransport transport,
    required int workchain,
    required String publicKey,
    required WalletType walletType,
  }) async {
    _transport = transport;
    _keystore = await Keystore.getInstance();
    _subscription = _receivePort.listen(_subscriptionListener);
    _onMessageSentSubscription = _onMessageSentSubject.listen(_onMessageSentListener);
    _onMessageExpiredSubscription = _onMessageExpiredSubject.listen(_onMessageExpiredListener);
    _onTransactionsFoundSubscription = _onTransactionsFoundSubject.listen(_onTransactionsFoundListener);

    final walletTypeStr = jsonEncode(walletType);

    final result = await _transport.nativeGqlTransport.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.ton_wallet_subscribe(
          port,
          _receivePort.sendPort.nativePort,
          ptr,
          workchain,
          publicKey.toNativeUtf8().cast<Int8>(),
          walletTypeStr.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );
    final ptr = Pointer.fromAddress(result).cast<Void>();

    _nativeTonWallet = NativeTonWallet(ptr);

    this.workchain = await _workchain;
    address = await _address;
    this.publicKey = await _publicKey;
    this.walletType = await _walletType;
    details = await _details;

    _timer = Timer.periodic(
      kGqlRefreshPeriod,
      _refreshTimer,
    );
  }

  Future<void> _initializeByAddress({
    required GqlTransport transport,
    required String address,
  }) async {
    _transport = transport;
    _keystore = await Keystore.getInstance();
    _subscription = _receivePort.listen(_subscriptionListener);
    _onMessageSentSubscription = _onMessageSentSubject.listen(_onMessageSentListener);
    _onMessageExpiredSubscription = _onMessageExpiredSubject.listen(_onMessageExpiredListener);
    _onTransactionsFoundSubscription = _onTransactionsFoundSubject.listen(_onTransactionsFoundListener);

    final result = await _transport.nativeGqlTransport.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.ton_wallet_subscribe_by_address(
          port,
          _receivePort.sendPort.nativePort,
          ptr,
          address.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );
    final ptr = Pointer.fromAddress(result).cast<Void>();

    _nativeTonWallet = NativeTonWallet(ptr);

    workchain = await _workchain;
    this.address = await _address;
    publicKey = await _publicKey;
    walletType = await _walletType;
    details = await _details;

    _timer = Timer.periodic(
      kGqlRefreshPeriod,
      _refreshTimer,
    );
  }

  Future<void> _initializeByExisting({
    required GqlTransport transport,
    required ExistingWalletInfo existingWalletInfo,
  }) async {
    _transport = transport;
    _keystore = await Keystore.getInstance();
    _subscription = _receivePort.listen(_subscriptionListener);
    _onMessageSentSubscription = _onMessageSentSubject.listen(_onMessageSentListener);
    _onMessageExpiredSubscription = _onMessageExpiredSubject.listen(_onMessageExpiredListener);
    _onTransactionsFoundSubscription = _onTransactionsFoundSubject.listen(_onTransactionsFoundListener);

    final existingWalletInfoStr = jsonEncode(existingWalletInfo);

    final result = await _transport.nativeGqlTransport.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.ton_wallet_subscribe_by_existing(
          port,
          _receivePort.sendPort.nativePort,
          ptr,
          existingWalletInfoStr.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );
    final ptr = Pointer.fromAddress(result).cast<Void>();

    _nativeTonWallet = NativeTonWallet(ptr);

    workchain = await _workchain;
    address = await _address;
    publicKey = await _publicKey;
    walletType = await _walletType;
    details = await _details;

    _timer = Timer.periodic(
      kGqlRefreshPeriod,
      _refreshTimer,
    );
  }

  Future<void> _subscriptionListener(dynamic data) async {
    try {
      if (data is! String) return;

      final json = jsonDecode(data) as Map<String, dynamic>;
      final message = SubscriptionHandlerMessage.fromJson(json);

      switch (message.event) {
        case 'on_message_sent':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnMessageSentPayload.fromJson(json);

          _onMessageSentSubject.add(payload);
          break;
        case 'on_message_expired':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnMessageExpiredPayload.fromJson(json);

          _onMessageExpiredSubject.add(payload);
          break;
        case 'on_state_changed':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnStateChangedPayload.fromJson(json);

          _onStateChangedSubject.add(payload);
          break;
        case 'on_transactions_found':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnTonWalletTransactionsFoundPayload.fromJson(json);

          _onTransactionsFoundSubject.add(payload);
          break;
      }
    } catch (err, st) {
      logger?.e(err, err, st);
    }
  }

  Future<void> _refreshTimer(Timer timer) async {
    try {
      if (_nativeTonWallet.isNull) {
        timer.cancel();
        return;
      }

      if (await pollingMethod == PollingMethod.reliable) return;

      await refresh();
    } catch (err, st) {
      logger?.e(err, err, st);
    }
  }

  void _onMessageSentListener(OnMessageSentPayload value) {
    final pending = [..._pendingTransactionsSubject.value.where((e) => e != value.pendingTransaction)];

    _pendingTransactionsSubject.add(pending);
  }

  void _onMessageExpiredListener(OnMessageExpiredPayload value) {
    final pending = [..._pendingTransactionsSubject.value.where((e) => e != value.pendingTransaction)];

    _pendingTransactionsSubject.add(pending);

    final expired = [..._expiredTransactionsSubject.value, value.pendingTransaction];

    _expiredTransactionsSubject.add(expired);
  }

  void _onTransactionsFoundListener(OnTonWalletTransactionsFoundPayload value) {
    final transactions = [..._transactionsSubject.value, ...value.transactions]
      ..sort((a, b) => b.transaction.createdAt.compareTo(a.transaction.createdAt));

    _transactionsSubject.add(transactions);
  }
}
