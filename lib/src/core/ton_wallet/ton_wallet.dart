import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/accounts_storage/models/wallet_type.dart';
import 'package:nekoton_flutter/src/core/contract_subscription/contract_subscription.dart';
import 'package:nekoton_flutter/src/core/models/contract_state.dart';
import 'package:nekoton_flutter/src/core/models/expiration.dart';
import 'package:nekoton_flutter/src/core/models/on_message_expired_payload.dart';
import 'package:nekoton_flutter/src/core/models/on_message_sent_payload.dart';
import 'package:nekoton_flutter/src/core/models/on_state_changed_payload.dart';
import 'package:nekoton_flutter/src/core/models/pending_transaction.dart';
import 'package:nekoton_flutter/src/core/models/polling_method.dart';
import 'package:nekoton_flutter/src/core/models/raw_contract_state.dart';
import 'package:nekoton_flutter/src/core/models/transaction.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/existing_wallet_info.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/multisig_pending_transaction.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/on_ton_wallet_transactions_found_payload.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/ton_wallet_details.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/ton_wallet_transaction_with_data.dart';
import 'package:nekoton_flutter/src/core/utils.dart';
import 'package:nekoton_flutter/src/crypto/models/signed_message.dart';
import 'package:nekoton_flutter/src/crypto/unsigned_message.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';
import 'package:nekoton_flutter/src/utils.dart';
import 'package:rxdart/rxdart.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_ton_wallet_free_ptr);

class TonWallet extends ContractSubscription implements Finalizable {
  late final Pointer<Void> _ptr;
  final Transport _transport;
  final _onMessageSentPort = ReceivePort();
  final _onMessageExpiredPort = ReceivePort();
  final _onStateChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  late final Stream<OnMessageSentPayload> _onMessageSentStream;
  late final Stream<OnMessageExpiredPayload> _onMessageExpiredStream;
  late final Stream<OnStateChangedPayload> onStateChangedStream;
  late final Stream<OnTonWalletTransactionsFoundPayload> _onTransactionsFoundStream;
  late final StreamSubscription<OnMessageExpiredPayload> _onMessageExpiredSubscription;
  late final StreamSubscription<OnTonWalletTransactionsFoundPayload>
      _onTransactionsFoundSubscription;
  final _transactionsSubject = BehaviorSubject<List<TonWalletTransactionWithData>>.seeded([]);
  final _pendingTransactionsSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);
  final _expiredTransactionsSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);
  final _unconfirmedTransactionsSubject =
      BehaviorSubject<List<MultisigPendingTransaction>>.seeded([]);
  late final int _workchain;
  late final String _address;
  late final String _publicKey;
  late final WalletType _walletType;
  late final TonWalletDetails _details;

  TonWallet._(this._transport);

  static Future<TonWallet> subscribe({
    required Transport transport,
    required int workchain,
    required String publicKey,
    required WalletType contract,
  }) async {
    final instance = TonWallet._(transport);
    await instance._subscribe(
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
    final instance = TonWallet._(transport);
    await instance._subscribeByAddress(address);
    return instance;
  }

  static Future<TonWallet> subscribeByExisting({
    required Transport transport,
    required ExistingWalletInfo existingWallet,
  }) async {
    final instance = TonWallet._(transport);
    await instance._subscribeByExisting(existingWallet);
    return instance;
  }

  Pointer<Void> get ptr => _ptr;

  @override
  Transport get transport => _transport;

  Stream<List<TonWalletTransactionWithData>> get transactionsStream =>
      _transactionsSubject.distinct((a, b) => listEquals(a, b));

  List<TonWalletTransactionWithData> get transactions => _transactionsSubject.value;

  Stream<List<PendingTransaction>> get pendingTransactionsStream =>
      _pendingTransactionsSubject.distinct((a, b) => listEquals(a, b));

  List<PendingTransaction> get pendingTransactions => _pendingTransactionsSubject.value;

  Stream<List<PendingTransaction>> get expiredTransactionsStream =>
      _expiredTransactionsSubject.distinct((a, b) => listEquals(a, b));

  List<PendingTransaction> get expiredTransactions => _expiredTransactionsSubject.value;

  Stream<List<MultisigPendingTransaction>> get unconfirmedTransactionsStream =>
      _unconfirmedTransactionsSubject.distinct((a, b) => listEquals(a, b));

  List<MultisigPendingTransaction> get unconfirmedTransactions =>
      _unconfirmedTransactionsSubject.value;

  int get workchain => _workchain;

  Future<int> get __workchain async {
    final workchain = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_workchain(
            port,
            ptr,
          ),
    );

    return workchain as int;
  }

  @override
  String get address => _address;

  Future<String> get __address async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_address(
            port,
            ptr,
          ),
    );

    final address = result as String;

    return address;
  }

  String get publicKey => _publicKey;

  Future<String> get __publicKey async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_public_key(
            port,
            ptr,
          ),
    );

    final publicKey = result as String;

    return publicKey;
  }

  WalletType get walletType => _walletType;

  Future<WalletType> get __walletType async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_wallet_type(
            port,
            ptr,
          ),
    );

    final json = result as Map<String, dynamic>;
    final walletType = WalletType.fromJson(json);

    return walletType;
  }

  Future<ContractState> get contractState async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_contract_state(
            port,
            ptr,
          ),
    );

    final json = result as Map<String, dynamic>;
    final contractState = ContractState.fromJson(json);

    return contractState;
  }

  Future<List<PendingTransaction>> get _pendingTransactions async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_pending_transactions(
            port,
            ptr,
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
            ptr,
          ),
    );

    final json = result as String;
    final pollingMethod = PollingMethod.values.firstWhere((e) => e.toString() == json);

    return pollingMethod;
  }

  TonWalletDetails get details => _details;

  Future<TonWalletDetails> get __details async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_details(
            port,
            ptr,
          ),
    );

    final json = result as Map<String, dynamic>;
    final details = TonWalletDetails.fromJson(json);

    return details;
  }

  Future<List<MultisigPendingTransaction>> get _unconfirmedTransactions async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_unconfirmed_transactions(
            port,
            ptr,
          ),
    );

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final unconfirmedTransactions =
        list.map((e) => MultisigPendingTransaction.fromJson(e)).toList();

    return unconfirmedTransactions;
  }

  Future<List<String>?> get custodians async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_custodians(
            port,
            ptr,
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
            ptr,
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
      (port) =>
          NekotonFlutter.instance().bindings.nt_ton_wallet_prepare_deploy_with_multiple_owners(
                port,
                ptr,
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
            ptr,
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
            ptr,
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
            ptr,
            signedMessageStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final fees = result as String;

    return fees;
  }

  Future<Transaction?> send(SignedMessage signedMessage) async {
    final pendingTransaction = await sendWithReliablePolling(() async {
      final signedMessageStr = jsonEncode(signedMessage);

      final result = await executeAsync(
        (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_send(
              port,
              ptr,
              signedMessageStr.toNativeUtf8().cast<Char>(),
            ),
      );

      final json = result as Map<String, dynamic>;
      final pendingTransaction = PendingTransaction.fromJson(json);

      return pendingTransaction;
    });

    _pendingTransactionsSubject.tryAdd(await _pendingTransactions);

    final transaction = await _onMessageSentStream
        .firstWhere((e) => e.pendingTransaction == pendingTransaction)
        .then((v) => v.transaction)
        .timeout(pendingTransaction.expireAt.toTimeout());

    return transaction;
  }

  @override
  Future<void> refresh() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_refresh(
            port,
            ptr,
          ),
    );

    _pendingTransactionsSubject.tryAdd(await _pendingTransactions);

    _unconfirmedTransactionsSubject.tryAdd(await _unconfirmedTransactions);
  }

  Future<void> preloadTransactions(String fromLt) => executeAsync(
        (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_preload_transactions(
              port,
              ptr,
              fromLt.toNativeUtf8().cast<Char>(),
            ),
      );

  @override
  Future<void> handleBlock(String block) async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_handle_block(
            port,
            ptr,
            block.toNativeUtf8().cast<Char>(),
          ),
    );

    _pendingTransactionsSubject.tryAdd(await _pendingTransactions);

    _unconfirmedTransactionsSubject.tryAdd(await _unconfirmedTransactions);
  }

  Future<void> dispose() async {
    await _onMessageExpiredSubscription.cancel();
    await _onTransactionsFoundSubscription.cancel();

    _onMessageSentPort.close();
    _onMessageExpiredPort.close();
    _onStateChangedPort.close();
    _onTransactionsFoundPort.close();

    await _transactionsSubject.close();
    await _pendingTransactionsSubject.close();
    await _expiredTransactionsSubject.close();
    await _unconfirmedTransactionsSubject.close();
  }

  Future<void> _subscribe({
    required int workchain,
    required String publicKey,
    required WalletType contract,
  }) =>
      _initialize(
        () async {
          final transportPtr = _transport.ptr;
          final transportTypeStr = jsonEncode(_transport.type.toString());
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

  Future<void> _subscribeByAddress(String address) => _initialize(
        () async {
          final transportPtr = _transport.ptr;
          final transportTypeStr = jsonEncode(_transport.type.toString());

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

  Future<void> _subscribeByExisting(ExistingWalletInfo existingWallet) => _initialize(
        () async {
          final transportPtr = _transport.ptr;
          final transportTypeStr = jsonEncode(_transport.type.toString());
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

  Future<void> _initialize(Future<int> Function() subscribe) async {
    _onMessageSentStream = _onMessageSentPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnMessageSentPayload.fromJson(json);
      return payload;
    }).asBroadcastStream();

    _onMessageExpiredStream = _onMessageExpiredPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnMessageExpiredPayload.fromJson(json);
      return payload;
    }).asBroadcastStream();

    onStateChangedStream = _onStateChangedPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnStateChangedPayload.fromJson(json);
      return payload;
    }).asBroadcastStream();

    _onTransactionsFoundStream = _onTransactionsFoundPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnTonWalletTransactionsFoundPayload.fromJson(json);
      return payload;
    }).asBroadcastStream();

    _onMessageExpiredSubscription = _onMessageExpiredStream.listen(
      (event) => _expiredTransactionsSubject.tryAdd(
        [
          ..._expiredTransactionsSubject.value,
          event.pendingTransaction,
        ]..sort((a, b) => a.compareTo(b)),
      ),
    );

    _onTransactionsFoundSubscription = _onTransactionsFoundStream.listen(
      (event) => _transactionsSubject.tryAdd(
        [
          ..._transactionsSubject.value,
          ...event.transactions,
        ]..sort((a, b) => a.transaction.compareTo(b.transaction)),
      ),
    );

    _ptr = Pointer.fromAddress(await subscribe()).cast<Void>();

    _nativeFinalizer.attach(this, _ptr);

    _workchain = await __workchain;
    _address = await __address;
    _publicKey = await __publicKey;
    _walletType = await __walletType;
    _details = await __details;
  }
}
