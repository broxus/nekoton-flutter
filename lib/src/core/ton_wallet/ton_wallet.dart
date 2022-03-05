import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

import '../../bindings.dart';
import '../../constants.dart';
import '../../core/keystore/keystore.dart';
import '../../crypto/models/sign_input.dart';
import '../../ffi_utils.dart';
import '../../models/pointed.dart';
import '../../transport/gql_transport.dart';
import '../../transport/models/transport_type.dart';
import '../../transport/transport.dart';
import '../../utils.dart';
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

class TonWallet implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;
  final _onMessageSentPort = ReceivePort();
  final _onMessageExpiredPort = ReceivePort();
  final _onStateChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  final _pendingTransactionsSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);
  final _unconfirmedTransactionsSubject = BehaviorSubject<List<MultisigPendingTransaction>>.seeded([]);
  late final Stream<OnMessageSentPayload> onMessageSentStream;
  late final Stream<OnMessageExpiredPayload> onMessageExpiredStream;
  late final Stream<OnStateChangedPayload> onStateChangedStream;
  late final Stream<OnTonWalletTransactionsFoundPayload> onTransactionsFoundStream;
  late final Stream<List<PendingTransaction>> pendingTransactionsStream;
  late final Stream<List<MultisigPendingTransaction>> unconfirmedTransactionsStream;
  late final Transport _transport;
  late final CustomRestartableTimer _backgroundRefreshTimer;
  final _workchainMemo = AsyncMemoizer<int>();
  final _addressMemo = AsyncMemoizer<String>();
  final _publicKeyMemo = AsyncMemoizer<String>();
  final _walletTypeMemo = AsyncMemoizer<WalletType>();
  final _detailsMemo = AsyncMemoizer<TonWalletDetails>();

  TonWallet._();

  static Future<TonWallet> subscribe({
    required Transport transport,
    required int workchain,
    required String publicKey,
    required WalletType walletType,
  }) async {
    final instance = TonWallet._();
    await instance._subscribe(
      transport: transport,
      workchain: workchain,
      publicKey: publicKey,
      walletType: walletType,
    );
    return instance;
  }

  static Future<TonWallet> subscribeByAddress({
    required Transport transport,
    required String address,
  }) async {
    final instance = TonWallet._();
    await instance._subscribeByAddress(
      transport: transport,
      address: address,
    );
    return instance;
  }

  static Future<TonWallet> subscribeByExisting({
    required Transport transport,
    required ExistingWalletInfo existingWalletInfo,
  }) async {
    final instance = TonWallet._();
    await instance._subscribeByExisting(
      transport: transport,
      existingWalletInfo: existingWalletInfo,
    );
    return instance;
  }

  Future<int> get workchain => _workchainMemo.runOnce(() async {
        final ptr = await clonePtr();

        final result = await executeAsync(
          (port) => bindings().get_ton_wallet_workchain(
            port,
            ptr,
          ),
        );

        return result;
      });

  Future<String> get address => _addressMemo.runOnce(() async {
        final ptr = await clonePtr();

        final result = await executeAsync(
          (port) => bindings().get_ton_wallet_address(
            port,
            ptr,
          ),
        );

        final address = cStringToDart(result);

        return address;
      });

  Future<String> get publicKey => _publicKeyMemo.runOnce(() async {
        final ptr = await clonePtr();

        final result = await executeAsync(
          (port) => bindings().get_ton_wallet_public_key(
            port,
            ptr,
          ),
        );

        final publicKey = cStringToDart(result);

        return publicKey;
      });

  Future<WalletType> get walletType => _walletTypeMemo.runOnce(() async {
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
      });

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

  Future<PollingMethod> get pollingMethod async {
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

  Future<TonWalletDetails> get details => _detailsMemo.runOnce(() async {
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
      });

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

    _pendingTransactionsSubject.add(await pendingTransactions);

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

    _pendingTransactionsSubject.add(await pendingTransactions);

    _unconfirmedTransactionsSubject.add(await unconfirmedTransactions);
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

  Future<void> handleBlock(String id) async {
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
        if (_ptr == null) return;

        _onMessageSentPort.close();
        _onMessageExpiredPort.close();
        _onStateChangedPort.close();
        _onTransactionsFoundPort.close();

        _pendingTransactionsSubject.close();
        _unconfirmedTransactionsSubject.close();

        _backgroundRefreshTimer.cancel();

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
  }) =>
      _initialize(
        transport: transport,
        subscribe: () async {
          final transportPtr = await transport.clonePtr();
          final transportType = transport.connectionData.type;
          final walletTypeStr = jsonEncode(walletType);

          return executeAsync(
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
        },
      );

  Future<void> _subscribeByAddress({
    required Transport transport,
    required String address,
  }) =>
      _initialize(
        transport: transport,
        subscribe: () async {
          final transportPtr = await transport.clonePtr();
          final transportType = transport.connectionData.type;

          return executeAsync(
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
        },
      );

  Future<void> _subscribeByExisting({
    required Transport transport,
    required ExistingWalletInfo existingWalletInfo,
  }) =>
      _initialize(
        transport: transport,
        subscribe: () async {
          final transportPtr = await transport.clonePtr();
          final transportType = transport.connectionData.type;
          final existingWalletInfoStr = jsonEncode(existingWalletInfo);

          return executeAsync(
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
        },
      );

  Future<void> _initialize({
    required Transport transport,
    required Future<int> Function() subscribe,
  }) async {
    onMessageSentStream = _onMessageSentPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnMessageSentPayload.fromJson(json);
      return payload;
    }).shareValue();

    onMessageExpiredStream = _onMessageExpiredPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnMessageExpiredPayload.fromJson(json);
      return payload;
    }).shareValue();

    onStateChangedStream = _onStateChangedPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnStateChangedPayload.fromJson(json);
      return payload;
    }).shareValue();

    onTransactionsFoundStream = _onTransactionsFoundPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnTonWalletTransactionsFoundPayload.fromJson(json);
      return payload;
    }).shareValue();

    pendingTransactionsStream = _pendingTransactionsSubject.stream;

    unconfirmedTransactionsStream = _unconfirmedTransactionsSubject.stream;

    _transport = transport;

    _ptr = Pointer.fromAddress(await subscribe()).cast<Void>();

    _backgroundRefreshTimer = CustomRestartableTimer(Duration.zero, _backgroundRefreshTimerCallback);
  }

  Future<void> _backgroundRefreshTimerCallback() async {
    if (_ptr == null) {
      _backgroundRefreshTimer.cancel();
      return;
    }

    try {
      final isGql = _transport.connectionData.type == TransportType.gql;
      final isReliable = await pollingMethod == PollingMethod.reliable;

      if (isGql && isReliable) {
        final transport = _transport as GqlTransport;
        final address = await this.address;

        final currentBlockId = await transport.getLatestBlockId(address);

        final nextId = await transport.waitForNextBlockId(
          currentBlockId: currentBlockId,
          address: address,
          timeout: kGqlTimeout.inMilliseconds,
        );

        await handleBlock(nextId);

        _backgroundRefreshTimer.reset(Duration.zero);
      } else {
        await refresh();

        final isReliable = await pollingMethod == PollingMethod.reliable;
        final duration = isReliable ? kShortRefreshInterval : kRefreshInterval;

        _backgroundRefreshTimer.reset(duration);
      }
    } catch (err, st) {
      logger?.w(err, err, st);
      _backgroundRefreshTimer.reset(Duration.zero);
    }
  }
}
