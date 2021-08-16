import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/keystore/keystore.dart';
import '../../crypto/models/derived_key_sign_params.dart';
import '../../crypto/models/encrypted_key_password.dart';
import '../../crypto/models/password.dart';
import '../../crypto/models/password_cache_behavior.dart';
import '../../crypto/models/sign_input.dart';
import '../../external/gql.dart';
import '../../ffi_utils.dart';
import '../../models/nekoton_exception.dart';
import '../../native_library.dart';
import '../accounts_storage/models/wallet_type.dart';
import '../keystore/models/key_store_entry.dart';
import '../models/contract_state.dart';
import '../models/expiration.dart';
import '../models/native_unsigned_message.dart';
import '../models/on_state_changed_payload.dart';
import '../models/pending_transaction.dart';
import '../models/subscription_handler_message.dart';
import '../models/transaction.dart';
import '../models/transaction_id.dart';
import '../models/unsigned_message.dart';
import 'models/existing_wallet_info.dart';
import 'models/multisig_pending_transaction.dart';
import 'models/native_ton_wallet.dart';
import 'models/on_message_expired_payload.dart';
import 'models/on_message_sent_payload.dart';
import 'models/on_ton_wallet_transactions_found_payload.dart';
import 'models/polling_method.dart';
import 'models/ton_wallet_details.dart';
import 'models/ton_wallet_transaction_with_data.dart';

Future<TonWallet> tonWalletSubscribe({
  required Keystore keystore,
  required int workchain,
  required KeyStoreEntry entry,
  required WalletType walletType,
  Logger? logger,
}) async {
  final tonWallet = TonWallet._();

  tonWallet._logger = logger;

  tonWallet._gql = await Gql.getInstance(logger: tonWallet._logger);
  tonWallet._keystore = keystore;
  tonWallet._entry = entry;
  tonWallet._subscription = tonWallet._receivePort.listen(tonWallet._subscriptionListener);

  final contractTypeStr = jsonEncode(walletType.toJson());
  final result = await proceedAsync((port) => tonWallet._nativeLibrary.bindings.ton_wallet_subscribe(
        port,
        tonWallet._receivePort.sendPort.nativePort,
        tonWallet._gql.nativeTransport.ptr!,
        workchain,
        entry.publicKey.toNativeUtf8().cast<Int8>(),
        contractTypeStr.toNativeUtf8().cast<Int8>(),
      ));
  final ptr = Pointer.fromAddress(result).cast<Void>();

  tonWallet.nativeTonWallet = NativeTonWallet(ptr);
  tonWallet._timer = Timer.periodic(
    const Duration(seconds: 15),
    tonWallet._refreshTimer,
  );
  tonWallet.address = await tonWallet._address;
  tonWallet.publicKey = await tonWallet._publicKey;
  tonWallet.walletType = await tonWallet._walletType;
  tonWallet.details = await tonWallet._details;
  tonWallet.custodians = await tonWallet._custodians;

  return tonWallet;
}

Future<TonWallet> tonWalletSubscribeByAddress({
  required String address,
  Logger? logger,
}) async {
  final tonWallet = TonWallet._();

  tonWallet._logger = logger;

  tonWallet._gql = await Gql.getInstance(logger: tonWallet._logger);
  tonWallet._subscription = tonWallet._receivePort.listen(tonWallet._subscriptionListener);

  final result = await proceedAsync((port) => tonWallet._nativeLibrary.bindings.ton_wallet_subscribe_by_address(
        port,
        tonWallet._receivePort.sendPort.nativePort,
        tonWallet._gql.nativeTransport.ptr!,
        address.toNativeUtf8().cast<Int8>(),
      ));
  final ptr = Pointer.fromAddress(result).cast<Void>();

  tonWallet.nativeTonWallet = NativeTonWallet(ptr);
  tonWallet._timer = Timer.periodic(
    const Duration(seconds: 15),
    tonWallet._refreshTimer,
  );
  tonWallet.address = await tonWallet._address;
  tonWallet.publicKey = await tonWallet._publicKey;
  tonWallet.walletType = await tonWallet._walletType;
  tonWallet.details = await tonWallet._details;
  tonWallet.custodians = await tonWallet._custodians;

  return tonWallet;
}

Future<TonWallet> tonWalletSubscribeByExisting({
  required Keystore keystore,
  required KeyStoreEntry entry,
  required ExistingWalletInfo existingWalletInfo,
  Logger? logger,
}) async {
  final tonWallet = TonWallet._();

  tonWallet._logger = logger;

  tonWallet._gql = await Gql.getInstance(logger: tonWallet._logger);
  tonWallet._keystore = keystore;
  tonWallet._entry = entry;
  tonWallet._subscription = tonWallet._receivePort.listen(tonWallet._subscriptionListener);

  final existingWalletInfoStr = jsonEncode(existingWalletInfo.toJson());
  final result = await proceedAsync((port) => tonWallet._nativeLibrary.bindings.ton_wallet_subscribe_by_existing(
        port,
        tonWallet._receivePort.sendPort.nativePort,
        tonWallet._gql.nativeTransport.ptr!,
        existingWalletInfoStr.toNativeUtf8().cast<Int8>(),
      ));
  final ptr = Pointer.fromAddress(result).cast<Void>();

  tonWallet.nativeTonWallet = NativeTonWallet(ptr);
  tonWallet._timer = Timer.periodic(
    const Duration(seconds: 15),
    tonWallet._refreshTimer,
  );
  tonWallet.address = await tonWallet._address;
  tonWallet.publicKey = await tonWallet._publicKey;
  tonWallet.walletType = await tonWallet._walletType;
  tonWallet.details = await tonWallet._details;
  tonWallet.custodians = await tonWallet._custodians;

  return tonWallet;
}

Future<void> tonWalletUnsubscribe(TonWallet tonWallet) async {
  await proceedAsync(
      (port) => tonWallet._nativeLibrary.bindings.ton_wallet_unsubscribe(port, tonWallet.nativeTonWallet.ptr!));
  tonWallet.nativeTonWallet.ptr = null;
  tonWallet._receivePort.close();
  tonWallet._subscription.cancel();
  tonWallet._timer.cancel();
  tonWallet._onMessageSentSubject.close();
  tonWallet._onMessageExpiredSubject.close();
  tonWallet._onStateChangedSubject.close();
  tonWallet._onTransactionsFoundSubject.close();
}

Future<List<ExistingWalletInfo>> findExistingWallets({
  required String publicKey,
  required int workchainId,
}) async {
  final nativeLibrary = NativeLibrary.instance();
  final gql = await Gql.getInstance();

  final result = await proceedAsync((port) => nativeLibrary.bindings.find_existing_wallets(
        port,
        gql.nativeTransport.ptr!,
        publicKey.toNativeUtf8().cast<Int8>(),
        workchainId,
      ));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as List<dynamic>;
  final jsonList = json.cast<Map<String, dynamic>>();
  final existingWallets = jsonList.map((e) => ExistingWalletInfo.fromJson(e)).toList();

  return existingWallets;
}

class TonWallet {
  final _receivePort = ReceivePort();
  final _nativeLibrary = NativeLibrary.instance();
  late final Logger? _logger;
  late final Gql _gql;
  late final Keystore? _keystore;
  late final KeyStoreEntry? _entry;
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
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_ton_wallet_address(
          port,
          nativeTonWallet.ptr!,
        ));
    final address = cStringToDart(result);

    return address;
  }

  Future<String> get _publicKey async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_ton_wallet_public_key(
          port,
          nativeTonWallet.ptr!,
        ));
    final publicKey = cStringToDart(result);

    return publicKey;
  }

  Future<WalletType> get _walletType async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_ton_wallet_wallet_type(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final walletType = WalletType.fromJson(json);

    return walletType;
  }

  Future<ContractState> get contractState async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_ton_wallet_contract_state(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final contractState = ContractState.fromJson(json);

    return contractState;
  }

  Future<List<PendingTransaction>> get pendingTransactions async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_ton_wallet_pending_transactions(
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
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_ton_wallet_polling_method(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string);
    final pollingMethod = PollingMethod.values.firstWhere((e) => describeEnum(e).pascalCase == json);

    return pollingMethod;
  }

  Future<TonWalletDetails> get _details async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_ton_wallet_details(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final details = TonWalletDetails.fromJson(json);

    return details;
  }

  Future<List<MultisigPendingTransaction>> get unconfirmedTransactions async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_ton_wallet_unconfirmed_transactions(
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
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_ton_wallet_custodians(
          port,
          nativeTonWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>?;
    final custodians = json?.cast<String>();

    return custodians;
  }

  Future<UnsignedMessage> prepareDeploy(Expiration expiration) async {
    final expirationStr = jsonEncode(expiration.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.ton_wallet_prepare_deploy(
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
    final expirationStr = jsonEncode(expiration.toJson());
    final custodiansStr = jsonEncode(custodians);

    final result = await proceedAsync((port) => _nativeLibrary.bindings.ton_wallet_prepare_deploy_with_multiple_owners(
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
  }) async {
    final expirationStr = jsonEncode(expiration.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.ton_wallet_prepare_transfer(
          port,
          nativeTonWallet.ptr!,
          _gql.nativeTransport.ptr!,
          expirationStr.toNativeUtf8().cast<Int8>(),
          destination.toNativeUtf8().cast<Int8>(),
          amount,
          body?.toNativeUtf8().cast<Int8>() ?? Pointer.fromAddress(0).cast<Int8>(),
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
    final expirationStr = jsonEncode(expiration.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.ton_wallet_prepare_confirm_transaction(
          port,
          nativeTonWallet.ptr!,
          _gql.nativeTransport.ptr!,
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
    final expirationStr = jsonEncode(expiration.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.prepare_add_ordinary_stake(
          port,
          nativeTonWallet.ptr!,
          _gql.nativeTransport.ptr!,
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
    final expirationStr = jsonEncode(expiration.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.prepare_withdraw_part(
          port,
          nativeTonWallet.ptr!,
          _gql.nativeTransport.ptr!,
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
      proceedAsync((port) => _nativeLibrary.bindings.ton_wallet_estimate_fees(
            port,
            nativeTonWallet.ptr!,
            message.nativeUnsignedMessage.ptr!,
          ));

  Future<PendingTransaction> send({
    required UnsignedMessage message,
    required String password,
  }) async {
    if (_keystore == null) {
      throw TonWalletReadOnlyException();
    }

    final currentBlockId = await _gql.getLatestBlockId(address);
    final signInput = await _getSignInput(password);
    final signInputStr = jsonEncode(signInput.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.ton_wallet_send(
          port,
          nativeTonWallet.ptr!,
          _keystore!.nativeKeystore.ptr!,
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

  Future<void> refresh() async => proceedAsync((port) => _nativeLibrary.bindings.ton_wallet_refresh(
        port,
        nativeTonWallet.ptr!,
      ));

  Future<void> preloadTransactions(TransactionId from) async {
    final fromStr = jsonEncode(from.toJson());

    await proceedAsync((port) => _nativeLibrary.bindings.ton_wallet_preload_transactions(
          port,
          nativeTonWallet.ptr!,
          fromStr.toNativeUtf8().cast<Int8>(),
        ));
  }

  Future<SignInput> _getSignInput(String password) async => _entry!.isLegacy
      ? EncryptedKeyPassword(
          publicKey: _entry!.publicKey,
          password: Password.explicit(
            password: password,
            cacheBehavior: const PasswordCacheBehavior.remove(),
          ),
        )
      : DerivedKeySignParams.byAccountId(
          masterKey: _entry!.masterKey,
          accountId: _entry!.accountId,
          password: Password.explicit(
            password: password,
            cacheBehavior: const PasswordCacheBehavior.remove(),
          ),
        );

  Future<void> _handleBlock(String id) async => proceedAsync((port) => _nativeLibrary.bindings.ton_wallet_handle_block(
        port,
        nativeTonWallet.ptr!,
        _gql.nativeTransport.ptr!,
        id.toNativeUtf8().cast<Int8>(),
      ));

  Future<void> _internalRefresh(String currentBlockId) async {
    for (var i = 0; 0 < 10; i++) {
      try {
        final nextBlockId = await _gql.waitForNextBlockId(
          currentBlockId: currentBlockId,
          address: address,
        );

        await _handleBlock(nextBlockId);
        await refresh();

        if (await pollingMethod == PollingMethod.manual) {
          break;
        }
      } catch (err, st) {
        _logger?.e(err, err, st);
      }
    }
  }

  Future<void> _refreshTimer(Timer timer) async {
    try {
      if (await pollingMethod == PollingMethod.reliable) {
        return;
      }

      await refresh();
    } catch (err, st) {
      _logger?.e(err, err, st);
    }
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

          if (!payload.batchInfo.old) {
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
      _logger?.e(err, err, st);
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
}
