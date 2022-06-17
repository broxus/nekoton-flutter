import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:ffi/ffi.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../bindings.dart';
import '../../crypto/models/signed_message.dart';
import '../../crypto/unsigned_message.dart';
import '../../ffi_utils.dart';
import '../../models/pointer_wrapper.dart';
import '../../transport/transport.dart';
import '../accounts_storage/models/wallet_type.dart';
import '../contract_subscription/contract_subscription.dart';
import '../models/contract_state.dart';
import '../models/expiration.dart';
import '../models/on_message_expired_payload.dart';
import '../models/on_message_sent_payload.dart';
import '../models/on_state_changed_payload.dart';
import '../models/pending_transaction.dart';
import '../models/polling_method.dart';
import '../models/raw_contract_state.dart';
import '../models/transaction.dart';
import '../models/transaction_id.dart';
import 'models/existing_wallet_info.dart';
import 'models/multisig_pending_transaction.dart';
import 'models/on_ton_wallet_transactions_found_payload.dart';
import 'models/ton_wallet_details.dart';
import 'models/ton_wallet_transaction_with_data.dart';

final _nativeFinalizer = NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_ton_wallet_free_ptr);

void _attach(PointerWrapper pointerWrapper) => _nativeFinalizer.attach(pointerWrapper, pointerWrapper.ptr);

class TonWallet extends ContractSubscription {
  late final PointerWrapper pointerWrapper;
  final _onMessageSentPort = ReceivePort();
  final _onMessageExpiredPort = ReceivePort();
  final _onStateChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  late final StreamSubscription _onMessageSentSubscription;
  late final StreamSubscription _onMessageExpiredSubscription;
  late final StreamSubscription _onTransactionsFoundSubscription;
  final _transactionsSubject = BehaviorSubject<List<TonWalletTransactionWithData>>.seeded([]);
  final _pendingTransactionsSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);
  final _unconfirmedTransactionsSubject = BehaviorSubject<List<MultisigPendingTransaction>>.seeded([]);
  final _sentMessagesSubject = BehaviorSubject<List<Tuple2<PendingTransaction, Transaction?>>>.seeded([]);
  final _expiredMessagesSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);
  late final Stream<ContractState> stateChangesStream;
  late final Stream<List<TonWalletTransactionWithData>> transactionsStream = _transactionsSubject;
  late final Stream<List<PendingTransaction>> pendingTransactionsStream = _pendingTransactionsSubject;
  late final Stream<List<MultisigPendingTransaction>> unconfirmedTransactionsStream = _unconfirmedTransactionsSubject;
  late final Stream<List<Tuple2<PendingTransaction, Transaction?>>> sentMessagesStream = _sentMessagesSubject;
  late final Stream<List<PendingTransaction>> expiredMessagesStream = _expiredMessagesSubject;
  @override
  late final Transport transport;
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
    required WalletType contract,
  }) async {
    final instance = TonWallet._();
    await instance._subscribe(
      transport: transport,
      workchain: workchain,
      publicKey: publicKey,
      contract: contract,
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
    required ExistingWalletInfo existingWallet,
  }) async {
    final instance = TonWallet._();
    await instance._subscribeByExisting(
      transport: transport,
      existingWallet: existingWallet,
    );
    return instance;
  }

  Future<int> get workchain => _workchainMemo.runOnce(() async {
        final workchain = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_workchain(
                port,
                pointerWrapper.ptr,
              ),
        );

        return workchain as int;
      });

  @override
  Future<String> get address => _addressMemo.runOnce(() async {
        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_address(
                port,
                pointerWrapper.ptr,
              ),
        );

        final address = result as String;

        return address;
      });

  Future<String> get publicKey => _publicKeyMemo.runOnce(() async {
        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_public_key(
                port,
                pointerWrapper.ptr,
              ),
        );

        final publicKey = result as String;

        return publicKey;
      });

  Future<WalletType> get walletType => _walletTypeMemo.runOnce(() async {
        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_wallet_type(
                port,
                pointerWrapper.ptr,
              ),
        );

        final json = result as Map<String, dynamic>;
        final walletType = WalletType.fromJson(json);

        return walletType;
      });

  Future<ContractState> get contractState async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_contract_state(
            port,
            pointerWrapper.ptr,
          ),
    );

    final json = result as Map<String, dynamic>;
    final contractState = ContractState.fromJson(json);

    return contractState;
  }

  Future<List<PendingTransaction>> get pendingTransactions async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_pending_transactions(
            port,
            pointerWrapper.ptr,
          ),
    );

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final pendingTransactions = list.map((e) => PendingTransaction.fromJson(e)).toList();

    return pendingTransactions;
  }

  @override
  Future<PollingMethod> get pollingMethod async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_polling_method(
            port,
            pointerWrapper.ptr,
          ),
    );

    final json = result as String;
    final pollingMethod = PollingMethod.values.firstWhere((e) => e.toString() == json);

    return pollingMethod;
  }

  Future<TonWalletDetails> get details => _detailsMemo.runOnce(() async {
        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_details(
                port,
                pointerWrapper.ptr,
              ),
        );

        final json = result as Map<String, dynamic>;
        final details = TonWalletDetails.fromJson(json);

        return details;
      });

  Future<List<MultisigPendingTransaction>> get unconfirmedTransactions async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_unconfirmed_transactions(
            port,
            pointerWrapper.ptr,
          ),
    );

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final unconfirmedTransactions = list.map((e) => MultisigPendingTransaction.fromJson(e)).toList();

    return unconfirmedTransactions;
  }

  Future<List<String>?> get custodians async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_custodians(
            port,
            pointerWrapper.ptr,
          ),
    );

    final json = result as List<dynamic>?;
    final custodians = json?.cast<String>();

    return custodians;
  }

  Future<UnsignedMessage> prepareDeploy(Expiration expiration) async {
    final expirationStr = jsonEncode(expiration);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_prepare_deploy(
            port,
            pointerWrapper.ptr,
            expirationStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final unsignedMessage = UnsignedMessage(Pointer.fromAddress(result as int).cast<Void>());

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareDeployWithMultipleOwners({
    required Expiration expiration,
    required List<String> custodians,
    required int reqConfirms,
  }) async {
    final expirationStr = jsonEncode(expiration);
    final custodiansStr = jsonEncode(custodians);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_prepare_deploy_with_multiple_owners(
            port,
            pointerWrapper.ptr,
            expirationStr.toNativeUtf8().cast<Char>(),
            custodiansStr.toNativeUtf8().cast<Char>(),
            reqConfirms,
          ),
    );

    final unsignedMessage = UnsignedMessage(Pointer.fromAddress(result as int).cast<Void>());

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareTransfer({
    required RawContractState contractState,
    required String publicKey,
    required String destination,
    required String amount,
    String? body,
    required bool bounce,
    required Expiration expiration,
  }) async {
    final contractStateStr = jsonEncode(contractState);
    final expirationStr = jsonEncode(expiration);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_prepare_transfer(
            port,
            pointerWrapper.ptr,
            contractStateStr.toNativeUtf8().cast<Char>(),
            publicKey.toNativeUtf8().cast<Char>(),
            destination.toNativeUtf8().cast<Char>(),
            amount.toNativeUtf8().cast<Char>(),
            bounce ? 1 : 0,
            body?.toNativeUtf8().cast<Char>() ?? nullptr,
            expirationStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final unsignedMessage = UnsignedMessage(Pointer.fromAddress(result as int).cast<Void>());

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareConfirmTransaction({
    required RawContractState contractState,
    required String publicKey,
    required String transactionId,
    required Expiration expiration,
  }) async {
    final contractStateStr = jsonEncode(contractState);
    final expirationStr = jsonEncode(expiration);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_prepare_confirm_transaction(
            port,
            pointerWrapper.ptr,
            contractStateStr.toNativeUtf8().cast<Char>(),
            publicKey.toNativeUtf8().cast<Char>(),
            transactionId.toNativeUtf8().cast<Char>(),
            expirationStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final unsignedMessage = UnsignedMessage(Pointer.fromAddress(result as int).cast<Void>());

    return unsignedMessage;
  }

  Future<String> estimateFees(SignedMessage signedMessage) async {
    final signedMessageStr = jsonEncode(signedMessage);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_estimate_fees(
            port,
            pointerWrapper.ptr,
            signedMessageStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final fees = result as String;

    return fees;
  }

  Future<PendingTransaction> send(SignedMessage signedMessage) async {
    final signedMessageStr = jsonEncode(signedMessage);

    await prepareReliablePolling();

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_send(
            port,
            pointerWrapper.ptr,
            signedMessageStr.toNativeUtf8().cast<Char>(),
          ),
    );

    skipRefreshTimer();

    final json = result as Map<String, dynamic>;
    final pendingTransaction = PendingTransaction.fromJson(json);

    if (!_pendingTransactionsSubject.isClosed) _pendingTransactionsSubject.add(await pendingTransactions);

    return pendingTransaction;
  }

  @override
  Future<void> refresh() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_refresh(
            port,
            pointerWrapper.ptr,
          ),
    );

    if (!_pendingTransactionsSubject.isClosed) _pendingTransactionsSubject.add(await pendingTransactions);

    if (!_unconfirmedTransactionsSubject.isClosed) _unconfirmedTransactionsSubject.add(await unconfirmedTransactions);
  }

  Future<void> preloadTransactions(TransactionId from) async {
    final fromStr = jsonEncode(from);

    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_preload_transactions(
            port,
            pointerWrapper.ptr,
            fromStr.toNativeUtf8().cast<Char>(),
          ),
    );
  }

  @override
  Future<void> handleBlock(String block) async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_handle_block(
            port,
            pointerWrapper.ptr,
            block.toNativeUtf8().cast<Char>(),
          ),
    );

    if (!_pendingTransactionsSubject.isClosed) _pendingTransactionsSubject.add(await pendingTransactions);

    if (!_unconfirmedTransactionsSubject.isClosed) _unconfirmedTransactionsSubject.add(await unconfirmedTransactions);
  }

  Future<void> dispose() async {
    await _onMessageSentSubscription.cancel();
    await _onMessageExpiredSubscription.cancel();
    await _onTransactionsFoundSubscription.cancel();

    _onMessageSentPort.close();
    _onMessageExpiredPort.close();
    _onStateChangedPort.close();
    _onTransactionsFoundPort.close();

    await _transactionsSubject.close();
    await _pendingTransactionsSubject.close();
    await _unconfirmedTransactionsSubject.close();
    await _sentMessagesSubject.close();
    await _expiredMessagesSubject.close();

    await pausePolling();
  }

  Future<void> _subscribe({
    required Transport transport,
    required int workchain,
    required String publicKey,
    required WalletType contract,
  }) =>
      _initialize(
        transport: transport,
        subscribe: () async {
          final transportPtr = transport.pointerWrapper.ptr;
          final transportTypeStr = jsonEncode(transport.type.toString());
          final contractStr = jsonEncode(contract);

          final result = await executeAsync(
            (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_subscribe(
                  port,
                  _onMessageSentPort.sendPort.nativePort,
                  _onMessageExpiredPort.sendPort.nativePort,
                  _onStateChangedPort.sendPort.nativePort,
                  _onTransactionsFoundPort.sendPort.nativePort,
                  transportPtr,
                  transportTypeStr.toNativeUtf8().cast<Char>(),
                  workchain,
                  publicKey.toNativeUtf8().cast<Char>(),
                  contractStr.toNativeUtf8().cast<Char>(),
                ),
          );

          return result as int;
        },
      );

  Future<void> _subscribeByAddress({
    required Transport transport,
    required String address,
  }) =>
      _initialize(
        transport: transport,
        subscribe: () async {
          final transportPtr = transport.pointerWrapper.ptr;
          final transportTypeStr = jsonEncode(transport.type.toString());

          final result = await executeAsync(
            (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_subscribe_by_address(
                  port,
                  _onMessageSentPort.sendPort.nativePort,
                  _onMessageExpiredPort.sendPort.nativePort,
                  _onStateChangedPort.sendPort.nativePort,
                  _onTransactionsFoundPort.sendPort.nativePort,
                  transportPtr,
                  transportTypeStr.toNativeUtf8().cast<Char>(),
                  address.toNativeUtf8().cast<Char>(),
                ),
          );

          return result as int;
        },
      );

  Future<void> _subscribeByExisting({
    required Transport transport,
    required ExistingWalletInfo existingWallet,
  }) =>
      _initialize(
        transport: transport,
        subscribe: () async {
          final transportPtr = transport.pointerWrapper.ptr;
          final transportTypeStr = jsonEncode(transport.type.toString());
          final existingWalletStr = jsonEncode(existingWallet);

          final result = await executeAsync(
            (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_subscribe_by_existing(
                  port,
                  _onMessageSentPort.sendPort.nativePort,
                  _onMessageExpiredPort.sendPort.nativePort,
                  _onStateChangedPort.sendPort.nativePort,
                  _onTransactionsFoundPort.sendPort.nativePort,
                  transportPtr,
                  transportTypeStr.toNativeUtf8().cast<Char>(),
                  existingWalletStr.toNativeUtf8().cast<Char>(),
                ),
          );

          return result as int;
        },
      );

  Future<void> _initialize({
    required Transport transport,
    required Future<int> Function() subscribe,
  }) async {
    this.transport = transport;

    _onMessageSentSubscription = _onMessageSentPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnMessageSentPayload.fromJson(json);
      return payload;
    }).listen(
      (event) {
        if (!_sentMessagesSubject.isClosed) {
          _sentMessagesSubject.add(
            [
              ..._sentMessagesSubject.value,
              Tuple2(event.pendingTransaction, event.transaction),
            ]..sort((a, b) => a.item1.compareTo(b.item1)),
          );
        }
      },
    );

    _onMessageExpiredSubscription = _onMessageExpiredPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnMessageExpiredPayload.fromJson(json);
      return payload;
    }).listen(
      (event) {
        if (!_expiredMessagesSubject.isClosed) {
          _expiredMessagesSubject.add(
            [
              ..._expiredMessagesSubject.value,
              event.pendingTransaction,
            ]..sort((a, b) => a.compareTo(b)),
          );
        }
      },
    );

    stateChangesStream = _onStateChangedPort
        .cast<String>()
        .map((e) {
          final json = jsonDecode(e) as Map<String, dynamic>;
          final payload = OnStateChangedPayload.fromJson(json);
          return payload;
        })
        .map((event) => event.newState)
        .asBroadcastStream();

    _onTransactionsFoundSubscription = _onTransactionsFoundPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnTonWalletTransactionsFoundPayload.fromJson(json);
      return payload;
    }).listen(
      (event) {
        if (!_transactionsSubject.isClosed) {
          _transactionsSubject.add(
            [
              ..._transactionsSubject.value,
              ...event.transactions,
            ]..sort((a, b) => a.transaction.compareTo(b.transaction)),
          );
        }
      },
    );

    pointerWrapper = PointerWrapper(Pointer.fromAddress(await subscribe()).cast<Void>());

    _attach(pointerWrapper);

    await startPolling();
  }
}
