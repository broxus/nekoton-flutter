import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart';

import '../../bindings.dart';
import '../../constants.dart';
import '../../core/keystore/keystore.dart';
import '../../crypto/models/sign_input.dart';
import '../../ffi_utils.dart';
import '../../models/pointed.dart';
import '../../transport/gql_transport.dart';
import '../../transport/models/transport_type.dart';
import '../../transport/transport.dart';
import '../accounts_storage/models/wallet_type.dart';
import '../models/contract_state.dart';
import '../models/expiration.dart';
import '../models/on_message_expired_payload.dart';
import '../models/on_message_sent_payload.dart';
import '../models/on_state_changed_payload.dart';
import '../models/pending_transaction.dart';
import '../models/polling_method.dart';
import '../models/transaction_id.dart';
import '../unsigned_message.dart';
import 'models/existing_wallet_info.dart';
import 'models/multisig_pending_transaction.dart';
import 'models/on_ton_wallet_transactions_found_payload.dart';
import 'models/ton_wallet_details.dart';
import 'models/ton_wallet_transaction_with_data.dart';

class TonWallet implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;
  final _onMessageSentPort = ReceivePort();
  final _onMessageExpiredPort = ReceivePort();
  final _onStateChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  late final Stream<OnMessageSentPayload> onMessageSentStream;
  late final Stream<OnMessageExpiredPayload> onMessageExpiredStream;
  late final Stream<OnStateChangedPayload> onStateChangedStream;
  late final Stream<OnTonWalletTransactionsFoundPayload> onTransactionsFoundStream;
  late final Transport _transport;
  late final StreamSubscription _onMessageSentSubscription;
  late final StreamSubscription _onMessageExpiredSubscription;
  late final StreamSubscription _onTransactionsFoundSubscription;
  late final int workchain;
  late final String address;
  late final String publicKey;
  late final WalletType walletType;
  late final TonWalletDetails details;
  final _transactionsSubject = BehaviorSubject<List<TonWalletTransactionWithData>>.seeded([]);
  final _pendingTransactionsSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);
  final _expiredTransactionsSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);

  TonWallet._();

  static Future<TonWallet> subscribe({
    required Transport transport,
    required int workchain,
    required String publicKey,
    required WalletType walletType,
  }) async {
    final tonWallet = TonWallet._();
    await tonWallet._subscribe(
      transport: transport,
      workchain: workchain,
      publicKey: publicKey,
      walletType: walletType,
    );
    return tonWallet;
  }

  static Future<TonWallet> subscribeByAddress({
    required Transport transport,
    required String address,
  }) async {
    final tonWallet = TonWallet._();
    await tonWallet._subscribeByAddress(
      transport: transport,
      address: address,
    );
    return tonWallet;
  }

  static Future<TonWallet> subscribeByExisting({
    required Transport transport,
    required ExistingWalletInfo existingWalletInfo,
  }) async {
    final tonWallet = TonWallet._();
    await tonWallet._subscribeByExisting(
      transport: transport,
      existingWalletInfo: existingWalletInfo,
    );
    return tonWallet;
  }

  Stream<List<TonWalletTransactionWithData>> get transactionsStream => _transactionsSubject.stream;

  Stream<List<PendingTransaction>> get pendingTransactionsStream => _pendingTransactionsSubject.stream;

  Stream<List<PendingTransaction>> get expiredTransactionsStream => _expiredTransactionsSubject.stream;

  Future<int> get _workchain async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_ton_wallet_workchain(
        port,
        ptr,
      ),
    );

    return result;
  }

  Future<String> get _address async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_ton_wallet_address(
        port,
        ptr,
      ),
    );

    final address = cStringToDart(result);

    return address;
  }

  Future<String> get _publicKey async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_ton_wallet_public_key(
        port,
        ptr,
      ),
    );

    final publicKey = cStringToDart(result);

    return publicKey;
  }

  Future<WalletType> get _walletType async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_ton_wallet_wallet_type(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final walletType = WalletType.fromJson(json);

    return walletType;
  }

  Future<ContractState> get contractState async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_ton_wallet_contract_state(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final contractState = ContractState.fromJson(json);

    return contractState;
  }

  Future<List<PendingTransaction>> get pendingTransactions async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_ton_wallet_pending_transactions(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final jsonList = json.cast<Map<String, dynamic>>();
    final pendingTransactions = jsonList.map((e) => PendingTransaction.fromJson(e)).toList();

    return pendingTransactions;
  }

  Future<PollingMethod> get _pollingMethod async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_ton_wallet_polling_method(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string);
    final pollingMethod = PollingMethod.values.firstWhere((e) => describeEnum(e) == json);

    return pollingMethod;
  }

  Future<TonWalletDetails> get _details async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_ton_wallet_details(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final details = TonWalletDetails.fromJson(json);

    return details;
  }

  Future<List<MultisigPendingTransaction>> get unconfirmedTransactions async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_ton_wallet_unconfirmed_transactions(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final jsonList = json.cast<Map<String, dynamic>>();
    final pendingTransactions = jsonList.map((e) => MultisigPendingTransaction.fromJson(e)).toList();

    return pendingTransactions;
  }

  Future<List<String>?> get custodians async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_ton_wallet_custodians(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>?;
    final custodians = json?.cast<String>();

    return custodians;
  }

  Future<UnsignedMessage> prepareDeploy(Expiration expiration) async {
    final ptr = await clonePtr();

    final expirationStr = jsonEncode(expiration);

    final result = await executeAsync(
      (port) => bindings().ton_wallet_prepare_deploy(
        port,
        ptr,
        expirationStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    final unsignedMessagePtr = Pointer.fromAddress(result).cast<Void>();
    final unsignedMessage = UnsignedMessage(unsignedMessagePtr);

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareDeployWithMultipleOwners({
    required Expiration expiration,
    required List<String> custodians,
    required int reqConfirms,
  }) async {
    final ptr = await clonePtr();

    final expirationStr = jsonEncode(expiration);
    final custodiansStr = jsonEncode(custodians);

    final result = await executeAsync(
      (port) => bindings().ton_wallet_prepare_deploy_with_multiple_owners(
        port,
        ptr,
        expirationStr.toNativeUtf8().cast<Int8>(),
        custodiansStr.toNativeUtf8().cast<Int8>(),
        reqConfirms,
      ),
    );

    final unsignedMessagePtr = Pointer.fromAddress(result).cast<Void>();
    final unsignedMessage = UnsignedMessage(unsignedMessagePtr);

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareTransfer({
    required String publicKey,
    required String destination,
    required String amount,
    String? body,
    bool isComment = true,
    required Expiration expiration,
  }) async {
    final ptr = await clonePtr();

    final transportPtr = await _transport.clonePtr();

    final transportType = _transport.connectionData.type;

    final expirationStr = jsonEncode(expiration);

    final result = await executeAsync(
      (port) => bindings().ton_wallet_prepare_transfer(
        port,
        ptr,
        transportPtr,
        transportType.index,
        publicKey.toNativeUtf8().cast<Int8>(),
        destination.toNativeUtf8().cast<Int8>(),
        amount.toNativeUtf8().cast<Int8>(),
        body?.toNativeUtf8().cast<Int8>() ?? nullptr,
        expirationStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    final unsignedMessagePtr = Pointer.fromAddress(result).cast<Void>();
    final unsignedMessage = UnsignedMessage(unsignedMessagePtr);

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareConfirmTransaction({
    required String publicKey,
    required String transactionId,
    required Expiration expiration,
  }) async {
    final ptr = await clonePtr();

    final transportPtr = await _transport.clonePtr();

    final transportType = _transport.connectionData.type;

    final expirationStr = jsonEncode(expiration);

    final result = await executeAsync(
      (port) => bindings().ton_wallet_prepare_confirm_transaction(
        port,
        ptr,
        transportPtr,
        transportType.index,
        publicKey.toNativeUtf8().cast<Int8>(),
        transactionId.toNativeUtf8().cast<Int8>(),
        expirationStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    final unsignedMessagePtr = Pointer.fromAddress(result).cast<Void>();
    final unsignedMessage = UnsignedMessage(unsignedMessagePtr);

    return unsignedMessage;
  }

  Future<String> estimateFees(UnsignedMessage message) async {
    final ptr = await clonePtr();

    final unsignedMessagePtr = await message.clonePtr();

    final result = await executeAsync(
      (port) => bindings().ton_wallet_estimate_fees(
        port,
        ptr,
        unsignedMessagePtr,
      ),
    );

    final fees = cStringToDart(result);

    return fees;
  }

  Future<PendingTransaction> send({
    required Keystore keystore,
    required UnsignedMessage message,
    required SignInput signInput,
  }) async {
    final ptr = await clonePtr();

    final keystorePtr = await keystore.clonePtr();

    final unsignedMessagePtr = await message.clonePtr();

    final signInputStr = jsonEncode(signInput);

    final result = await executeAsync(
      (port) => bindings().ton_wallet_send(
        port,
        ptr,
        keystorePtr,
        unsignedMessagePtr,
        signInputStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final pendingTransaction = PendingTransaction.fromJson(json);

    final pending = [
      pendingTransaction,
      ..._pendingTransactionsSubject.value,
    ]..sort();

    _pendingTransactionsSubject.add(pending);

    return pendingTransaction;
  }

  Future<void> refresh() async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => bindings().ton_wallet_refresh(
        port,
        ptr,
      ),
    );
  }

  Future<void> preloadTransactions(TransactionId from) async {
    final ptr = await clonePtr();

    final fromStr = jsonEncode(from);

    await executeAsync(
      (port) => bindings().ton_wallet_preload_transactions(
        port,
        ptr,
        fromStr.toNativeUtf8().cast<Int8>(),
      ),
    );
  }

  Future<void> _handleBlock(String id) async {
    final ptr = await clonePtr();

    final transportPtr = await _transport.clonePtr();

    final transportType = _transport.connectionData.type;

    await executeAsync(
      (port) => bindings().ton_wallet_handle_block(
        port,
        ptr,
        transportPtr,
        transportType.index,
        id.toNativeUtf8().cast<Int8>(),
      ),
    );
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Ton wallet use after free');

        final ptr = bindings().clone_ton_wallet_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Ton wallet use after free');

        _onMessageSentSubscription.cancel();
        _onMessageExpiredSubscription.cancel();
        _onTransactionsFoundSubscription.cancel();

        _transactionsSubject.close();
        _pendingTransactionsSubject.close();
        _expiredTransactionsSubject.close();

        _onMessageSentPort.close();
        _onMessageExpiredPort.close();
        _onStateChangedPort.close();
        _onTransactionsFoundPort.close();

        bindings().free_ton_wallet_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _subscribe({
    required Transport transport,
    required int workchain,
    required String publicKey,
    required WalletType walletType,
  }) async {
    final transportPtr = await transport.clonePtr();

    final transportType = transport.connectionData.type;

    final walletTypeStr = jsonEncode(walletType);

    final result = await executeAsync(
      (port) => bindings().ton_wallet_subscribe(
        port,
        _onMessageSentPort.sendPort.nativePort,
        _onMessageExpiredPort.sendPort.nativePort,
        _onStateChangedPort.sendPort.nativePort,
        _onTransactionsFoundPort.sendPort.nativePort,
        transportPtr,
        transportType.index,
        workchain,
        publicKey.toNativeUtf8().cast<Int8>(),
        walletTypeStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    _ptr = Pointer.fromAddress(result).cast<Void>();

    await _initialize(
      transport: transport,
    );
  }

  Future<void> _subscribeByAddress({
    required Transport transport,
    required String address,
  }) async {
    final transportPtr = await transport.clonePtr();

    final transportType = transport.connectionData.type;

    final result = await executeAsync(
      (port) => bindings().ton_wallet_subscribe_by_address(
        port,
        _onMessageSentPort.sendPort.nativePort,
        _onMessageExpiredPort.sendPort.nativePort,
        _onStateChangedPort.sendPort.nativePort,
        _onTransactionsFoundPort.sendPort.nativePort,
        transportPtr,
        transportType.index,
        address.toNativeUtf8().cast<Int8>(),
      ),
    );

    _ptr = Pointer.fromAddress(result).cast<Void>();

    await _initialize(
      transport: transport,
    );
  }

  Future<void> _subscribeByExisting({
    required Transport transport,
    required ExistingWalletInfo existingWalletInfo,
  }) async {
    final transportPtr = await transport.clonePtr();

    final transportType = transport.connectionData.type;

    final existingWalletInfoStr = jsonEncode(existingWalletInfo);

    final result = await executeAsync(
      (port) => bindings().ton_wallet_subscribe_by_existing(
        port,
        _onMessageSentPort.sendPort.nativePort,
        _onMessageExpiredPort.sendPort.nativePort,
        _onStateChangedPort.sendPort.nativePort,
        _onTransactionsFoundPort.sendPort.nativePort,
        transportPtr,
        transportType.index,
        existingWalletInfoStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    _ptr = Pointer.fromAddress(result).cast<Void>();

    await _initialize(
      transport: transport,
    );
  }

  Future<void> _initialize({
    required Transport transport,
  }) async {
    onMessageSentStream = _onMessageSentPort.asBroadcastStream().cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnMessageSentPayload.fromJson(json);
      return payload;
    });

    onMessageExpiredStream = _onMessageExpiredPort.asBroadcastStream().cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnMessageExpiredPayload.fromJson(json);
      return payload;
    });

    onStateChangedStream = _onStateChangedPort.asBroadcastStream().cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnStateChangedPayload.fromJson(json);
      return payload;
    });

    onTransactionsFoundStream = _onTransactionsFoundPort.asBroadcastStream().cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnTonWalletTransactionsFoundPayload.fromJson(json);
      return payload;
    });

    _transport = transport;

    _onMessageSentSubscription = onMessageSentStream.listen(_onMessageSentListener);
    _onMessageExpiredSubscription = onMessageExpiredStream.listen(_onMessageExpiredListener);
    _onTransactionsFoundSubscription = onTransactionsFoundStream.listen(_onTransactionsFoundListener);

    workchain = await _workchain;
    address = await _address;
    publicKey = await _publicKey;
    walletType = await _walletType;
    details = await _details;

    _refreshCycle();
  }

  void _onMessageSentListener(OnMessageSentPayload value) {
    final pending = [
      ..._pendingTransactionsSubject.value.where((e) => e != value.pendingTransaction),
    ]..sort();

    _pendingTransactionsSubject.add(pending);
  }

  void _onMessageExpiredListener(OnMessageExpiredPayload value) {
    final pending = [
      ..._pendingTransactionsSubject.value.where((e) => e != value.pendingTransaction),
    ]..sort();

    _pendingTransactionsSubject.add(pending);

    final expired = [
      ..._expiredTransactionsSubject.value,
      value.pendingTransaction,
    ]..sort();

    _expiredTransactionsSubject.add(expired);
  }

  void _onTransactionsFoundListener(OnTonWalletTransactionsFoundPayload value) {
    final transactions = [
      ..._transactionsSubject.value,
      ...value.transactions,
    ]..sort();

    _transactionsSubject.add(transactions);
  }

  Future<void> _refreshCycle() async {
    while (_ptr != null) {
      try {
        if (_transport.connectionData.type == TransportType.gql && await _pollingMethod == PollingMethod.reliable) {
          final transport = _transport as GqlTransport;

          final currentBlockId = await transport.getLatestBlockId(address);

          final nextId = await transport.waitForNextBlockId(
            currentBlockId: currentBlockId,
            address: address,
            timeout: kGqlTimeout.inMilliseconds,
          );

          await _handleBlock(nextId);
        } else {
          await refresh();

          await Future.delayed(await _pollingMethod == PollingMethod.reliable ? kRefreshPeriod : kJrpcRefreshPeriod);
        }
      } catch (err, st) {
        nekotonErrorsSubject.add(Tuple2(err, st));
      }
    }
  }
}
