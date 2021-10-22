import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../core/keystore/keystore.dart';
import '../../ffi_utils.dart';
import '../../models/nekoton_exception.dart';
import '../../nekoton.dart';
import '../../transport/gql_transport.dart';
import '../accounts_storage/models/wallet_type.dart';
import '../keystore/models/key_store_entry.dart';
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
import '../models/transactions_batch_type.dart';
import '../models/unsigned_message.dart';
import 'models/existing_wallet_info.dart';
import 'models/multisig_pending_transaction.dart';
import 'models/native_ton_wallet.dart';
import 'models/on_ton_wallet_transactions_found_payload.dart';
import 'models/ton_wallet_details.dart';
import 'models/ton_wallet_transaction_with_data.dart';

class TonWallet implements Comparable<TonWallet> {
  final _receivePort = ReceivePort();
  late final GqlTransport _transport;
  late final Keystore _keystore;
  late final NativeTonWallet nativeTonWallet;
  late final StreamSubscription _subscription;
  late final Timer _timer;
  late final String address;
  late final String publicKey;
  late final WalletType walletType;
  late final TonWalletDetails details;
  late final List<String>? custodians;
  final _onMessageSentSubject = BehaviorSubject<Map<PendingTransaction, Transaction>>.seeded({});
  final _onMessageExpiredSubject = BehaviorSubject<List<Transaction>>.seeded([]);
  final _onStateChangedSubject = BehaviorSubject<ContractState>();
  final _onTransactionsFoundSubject = BehaviorSubject<List<TonWalletTransactionWithData>>.seeded([]);

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
    required KeyStoreEntry entry,
    required ExistingWalletInfo existingWalletInfo,
  }) async {
    final tonWallet = TonWallet._();
    await tonWallet._initializeByExisting(
      transport: transport,
      entry: entry,
      existingWalletInfo: existingWalletInfo,
    );
    return tonWallet;
  }

  Stream<List<Transaction>> get onMessageSentStream => _onMessageSentSubject.stream.transform<List<Transaction>>(
        StreamTransformer.fromHandlers(
          handleData: (Map<PendingTransaction, Transaction> data, EventSink<List<Transaction>> sink) => sink.add(
            data.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          ),
        ),
      );

  Stream<List<Transaction>> get onMessageExpiredStream => _onMessageExpiredSubject.stream;

  Stream<ContractState> get onStateChangedStream => _onStateChangedSubject.stream;

  Stream<List<TonWalletTransactionWithData>> get onTransactionsFoundStream => _onTransactionsFoundSubject.stream;

  Future<String> get _address async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_ton_wallet_address(
          port,
          nativeTonWallet.ptr!,
        ));
    final address = cStringToDart(result);

    return address;
  }

  Future<String> get _publicKey async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_ton_wallet_public_key(
          port,
          nativeTonWallet.ptr!,
        ));
    final publicKey = cStringToDart(result);

    return publicKey;
  }

  Future<WalletType> get _walletType async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_ton_wallet_wallet_type(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final walletType = WalletType.fromJson(json);

    return walletType;
  }

  Future<ContractState> get contractState async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_ton_wallet_contract_state(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final contractState = ContractState.fromJson(json);

    return contractState;
  }

  Future<List<PendingTransaction>> get pendingTransactions async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_ton_wallet_pending_transactions(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final jsonList = json.cast<Map<String, dynamic>>();
    final pendingTransactions = jsonList.map((e) => PendingTransaction.fromJson(e)).toList();

    return pendingTransactions;
  }

  Future<PollingMethod> get pollingMethod async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_ton_wallet_polling_method(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string);
    final pollingMethod = PollingMethod.values.firstWhere((e) => describeEnum(e) == json);

    return pollingMethod;
  }

  Future<TonWalletDetails> get _details async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_ton_wallet_details(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final details = TonWalletDetails.fromJson(json);

    return details;
  }

  Future<List<MultisigPendingTransaction>> get unconfirmedTransactions async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_ton_wallet_unconfirmed_transactions(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final jsonList = json.cast<Map<String, dynamic>>();
    final pendingTransactions = jsonList.map((e) => MultisigPendingTransaction.fromJson(e)).toList();

    return pendingTransactions;
  }

  Future<List<String>?> get _custodians async {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.get_ton_wallet_custodians(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>?;
    final custodians = json?.cast<String>();

    return custodians;
  }

  Future<UnsignedMessage> prepareDeploy(Expiration expiration) async {
    final expirationStr = jsonEncode(expiration);

    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_prepare_deploy(
          port,
          nativeTonWallet.ptr!,
          expirationStr.toNativeUtf8().cast<Int8>(),
        ));

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

    final result =
        await proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_prepare_deploy_with_multiple_owners(
              port,
              nativeTonWallet.ptr!,
              expirationStr.toNativeUtf8().cast<Int8>(),
              custodiansStr.toNativeUtf8().cast<Int8>(),
              reqConfirms,
            ));

    final ptr = Pointer.fromAddress(result).cast<Void>();
    final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
    final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareTransfer({
    required Expiration expiration,
    required String destination,
    required int amount,
    String? body,
    bool isComment = true,
  }) async {
    final expirationStr = jsonEncode(expiration);

    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_prepare_transfer(
          port,
          nativeTonWallet.ptr!,
          _transport.nativeGqlTransport.ptr!,
          expirationStr.toNativeUtf8().cast<Int8>(),
          destination.toNativeUtf8().cast<Int8>(),
          amount,
          body?.toNativeUtf8().cast<Int8>() ?? Pointer.fromAddress(0).cast<Int8>(),
          isComment ? 1 : 0,
        ));

    final ptr = Pointer.fromAddress(result).cast<Void>();
    final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
    final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareConfirmTransaction({
    required int transactionId,
    required Expiration expiration,
  }) async {
    final expirationStr = jsonEncode(expiration);

    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_prepare_confirm_transaction(
          port,
          nativeTonWallet.ptr!,
          _transport.nativeGqlTransport.ptr!,
          transactionId,
          expirationStr.toNativeUtf8().cast<Int8>(),
        ));

    final ptr = Pointer.fromAddress(result).cast<Void>();
    final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
    final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareAddOrdinaryStake({
    required Expiration expiration,
    required String depool,
    required int depoolFee,
    required int stake,
  }) async {
    final expirationStr = jsonEncode(expiration);

    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.prepare_add_ordinary_stake(
          port,
          nativeTonWallet.ptr!,
          _transport.nativeGqlTransport.ptr!,
          expirationStr.toNativeUtf8().cast<Int8>(),
          depool.toNativeUtf8().cast<Int8>(),
          depoolFee,
          stake,
        ));

    final ptr = Pointer.fromAddress(result).cast<Void>();
    final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
    final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareWithdrawPart({
    required Expiration expiration,
    required String depool,
    required int depoolFee,
    required int withdrawValue,
  }) async {
    final expirationStr = jsonEncode(expiration);

    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.prepare_withdraw_part(
          port,
          nativeTonWallet.ptr!,
          _transport.nativeGqlTransport.ptr!,
          expirationStr.toNativeUtf8().cast<Int8>(),
          depool.toNativeUtf8().cast<Int8>(),
          depoolFee,
          withdrawValue,
        ));

    final ptr = Pointer.fromAddress(result).cast<Void>();
    final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
    final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

    return unsignedMessage;
  }

  Future<int> estimateFees(UnsignedMessage message) async =>
      proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_estimate_fees(
            port,
            nativeTonWallet.ptr!,
            message.nativeUnsignedMessage.ptr!,
          ));

  Future<PendingTransaction> send({
    required UnsignedMessage message,
    required String password,
  }) async {
    final list = await _keystore.entries;
    final entry = list.firstWhereOrNull((e) => e.publicKey == publicKey);

    if (entry == null) {
      throw TonWalletReadOnlyException();
    }

    final currentBlockId = await _transport.getLatestBlockId(address);
    final signInput = await _keystore.getSignInput(
      entry: entry,
      password: password,
    );
    final signInputStr = jsonEncode(signInput);

    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_send(
          port,
          nativeTonWallet.ptr!,
          _keystore.nativeKeystore.ptr!,
          message.nativeUnsignedMessage.ptr!,
          signInputStr.toNativeUtf8().cast<Int8>(),
        ));
    message.nativeUnsignedMessage.ptr = null;

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final transaction = PendingTransaction.fromJson(json);

    _internalRefresh(currentBlockId);

    return transaction;
  }

  Future<void> refresh() async => proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_refresh(
        port,
        nativeTonWallet.ptr!,
      ));

  Future<void> preloadTransactions(TransactionId from) async {
    final fromStr = jsonEncode(from);

    await proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_preload_transactions(
          port,
          nativeTonWallet.ptr!,
          fromStr.toNativeUtf8().cast<Int8>(),
        ));
  }

  Future<Transaction> waitForTransaction(PendingTransaction pendingTransaction) async {
    final completer = Completer<Transaction>();

    _onMessageSentSubject.firstWhere((e) => e.keys.contains(pendingTransaction)).then((value) async {
      final transaction = value[pendingTransaction]!;

      final tuple =
          await Rx.combineLatest2<List<Transaction>, List<Transaction>, Tuple2<List<Transaction>, List<Transaction>>>(
        _onTransactionsFoundSubject.map((e) => e.map((e) => e.transaction).toList()),
        _onMessageExpiredSubject,
        (a, b) => Tuple2(a, b),
      ).firstWhere((e) => e.item1.contains(transaction) || e.item2.contains(transaction)).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          completer.completeError(Exception('Transaction timeout'));
          throw Exception();
        },
      );

      if (tuple.item1.contains(transaction)) {
        completer.complete(transaction);
      } else {
        completer.completeError(Exception('Transaction not found'));
      }
    }).timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        completer.completeError(Exception('Transaction timeout'));
      },
    );

    return completer.future;
  }

  void free() {
    nativeLibraryInstance.bindings.free_ton_wallet(
      nativeTonWallet.ptr!,
    );
    nativeTonWallet.ptr = null;
    _receivePort.close();
    _subscription.cancel();
    _timer.cancel();
    _onMessageSentSubject.close();
    _onMessageExpiredSubject.close();
    _onStateChangedSubject.close();
    _onTransactionsFoundSubject.close();
  }

  Future<void> _handleBlock(String id) async =>
      proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_handle_block(
            port,
            nativeTonWallet.ptr!,
            _transport.nativeGqlTransport.ptr!,
            id.toNativeUtf8().cast<Int8>(),
          ));

  Future<void> _internalRefresh(String currentBlockId) async {
    for (var i = 0; 0 < 10; i++) {
      try {
        final nextBlockId = await _transport.waitForNextBlockId(
          currentBlockId: currentBlockId,
          address: address,
        );

        await _handleBlock(nextBlockId);
        await refresh();

        if (await pollingMethod == PollingMethod.manual) {
          break;
        }
      } catch (err, st) {
        nekotonLogger?.e(err, err, st);
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

    final walletTypeStr = jsonEncode(walletType);
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_subscribe(
          port,
          _receivePort.sendPort.nativePort,
          _transport.nativeGqlTransport.ptr!,
          workchain,
          publicKey.toNativeUtf8().cast<Int8>(),
          walletTypeStr.toNativeUtf8().cast<Int8>(),
        ));
    final ptr = Pointer.fromAddress(result).cast<Void>();

    nativeTonWallet = NativeTonWallet(ptr);
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      _refreshTimer,
    );
    address = await _address;
    this.publicKey = await _publicKey;
    this.walletType = await _walletType;
    details = await _details;
    custodians = await _custodians;
  }

  Future<void> _initializeByAddress({
    required GqlTransport transport,
    required String address,
  }) async {
    _transport = transport;
    _subscription = _receivePort.listen(_subscriptionListener);

    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_subscribe_by_address(
          port,
          _receivePort.sendPort.nativePort,
          _transport.nativeGqlTransport.ptr!,
          address.toNativeUtf8().cast<Int8>(),
        ));
    final ptr = Pointer.fromAddress(result).cast<Void>();

    nativeTonWallet = NativeTonWallet(ptr);
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      _refreshTimer,
    );
    this.address = await _address;
    publicKey = await _publicKey;
    walletType = await _walletType;
    details = await _details;
    custodians = await _custodians;
  }

  Future<void> _initializeByExisting({
    required GqlTransport transport,
    required KeyStoreEntry entry,
    required ExistingWalletInfo existingWalletInfo,
  }) async {
    _transport = transport;
    _keystore = await Keystore.getInstance();
    _subscription = _receivePort.listen(_subscriptionListener);

    final existingWalletInfoStr = jsonEncode(existingWalletInfo);
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.ton_wallet_subscribe_by_existing(
          port,
          _receivePort.sendPort.nativePort,
          _transport.nativeGqlTransport.ptr!,
          existingWalletInfoStr.toNativeUtf8().cast<Int8>(),
        ));
    final ptr = Pointer.fromAddress(result).cast<Void>();

    nativeTonWallet = NativeTonWallet(ptr);
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      _refreshTimer,
    );
    address = await _address;
    publicKey = await _publicKey;
    walletType = await _walletType;
    details = await _details;
    custodians = await _custodians;
  }

  Future<void> _subscriptionListener(dynamic data) async {
    try {
      if (data is! String) {
        return;
      }

      final json = jsonDecode(data) as Map<String, dynamic>;
      final message = SubscriptionHandlerMessage.fromJson(json);

      switch (message.event) {
        case "on_message_sent":
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnMessageSentPayload.fromJson(json);

          final sent = {
            ..._onMessageSentSubject.value,
            payload.pendingTransaction: payload.transaction,
          };

          _onMessageSentSubject.add(sent);
          break;
        case "on_message_expired":
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnMessageExpiredPayload.fromJson(json);

          final sent = {..._onMessageSentSubject.value};
          final transaction = sent.remove(payload.pendingTransaction);

          if (transaction != null) {
            _onMessageSentSubject.add(sent);

            final expired = [
              ..._onMessageExpiredSubject.value,
              transaction,
            ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            _onMessageExpiredSubject.add(expired);
          }

          break;
        case "on_state_changed":
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnStateChangedPayload.fromJson(json);

          _onStateChangedSubject.add(payload.newState);
          break;
        case "on_transactions_found":
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnTonWalletTransactionsFoundPayload.fromJson(json);

          if (payload.batchInfo.batchType == TransactionsBatchType.newTransactions) {
            final sent = {..._onMessageSentSubject.value};

            final list = <Transaction>[];

            for (final transaction in sent.values) {
              if (payload.transactions.firstWhereOrNull((e) => e.transaction == transaction) != null) {
                list.add(transaction);
              }
            }

            for (final transaction in list) {
              sent.removeWhere((key, value) => value == transaction);
            }

            if (list.isNotEmpty) {
              _onMessageSentSubject.add(sent);
            }
          }

          final transactions = [
            ..._onTransactionsFoundSubject.value,
            ...payload.transactions,
          ]..sort((a, b) => b.transaction.createdAt.compareTo(a.transaction.createdAt));

          _onTransactionsFoundSubject.add(transactions);
          break;
      }
    } catch (err, st) {
      nekotonLogger?.e(err, err, st);
    }
  }

  Future<void> _refreshTimer(Timer timer) async {
    try {
      if (await pollingMethod == PollingMethod.reliable) {
        return;
      }

      await refresh();
    } catch (err, st) {
      nekotonLogger?.e(err, err, st);
    }
  }

  @override
  String toString() => 'TonWallet(${nativeTonWallet.ptr?.address})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      other is TonWallet && other.nativeTonWallet.ptr?.address == nativeTonWallet.ptr?.address;

  @override
  int get hashCode => nativeTonWallet.ptr?.address ?? 0;

  @override
  int compareTo(TonWallet other) => walletType.toInt().compareTo(other.walletType.toInt());
}

Future<List<ExistingWalletInfo>> findExistingWallets({
  required GqlTransport transport,
  required String publicKey,
  required int workchainId,
}) async {
  final result = await proceedAsync((port) => nativeLibraryInstance.bindings.find_existing_wallets(
        port,
        transport.nativeGqlTransport.ptr!,
        publicKey.toNativeUtf8().cast<Int8>(),
        workchainId,
      ));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as List<dynamic>;
  final jsonList = json.cast<Map<String, dynamic>>();
  final existingWallets = jsonList.map((e) => ExistingWalletInfo.fromJson(e)).toList();

  return existingWallets;
}
