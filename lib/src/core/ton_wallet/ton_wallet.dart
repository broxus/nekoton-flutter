import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/accounts_storage/models/wallet_type.dart';
import 'package:nekoton_flutter/src/core/models/contract_state.dart';
import 'package:nekoton_flutter/src/core/models/expiration.dart';
import 'package:nekoton_flutter/src/core/models/pending_transaction.dart';
import 'package:nekoton_flutter/src/core/models/polling_method.dart';
import 'package:nekoton_flutter/src/core/models/raw_contract_state.dart';
import 'package:nekoton_flutter/src/core/models/transaction.dart';
import 'package:nekoton_flutter/src/core/models/transaction_with_data.dart';
import 'package:nekoton_flutter/src/core/models/transactions_batch_info.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/existing_wallet_info.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/multisig_pending_transaction.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/ton_wallet_details.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/transaction_additional_info.dart';
import 'package:nekoton_flutter/src/crypto/models/signed_message.dart';
import 'package:nekoton_flutter/src/crypto/unsigned_message.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';
import 'package:tuple/tuple.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_ton_wallet_free_ptr);

class TonWallet implements Finalizable {
  late final Pointer<Void> _ptr;
  final Transport _transport;
  final _onMessageSentPort = ReceivePort();
  final _onMessageExpiredPort = ReceivePort();
  final _onStateChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  late final Stream<Tuple2<PendingTransaction, Transaction?>> onMessageSentStream;
  late final Stream<PendingTransaction> onMessageExpiredStream;
  late final Stream<ContractState> onStateChangedStream;
  late final Stream<
          Tuple2<List<TransactionWithData<TransactionAdditionalInfo?>>, TransactionsBatchInfo>>
      onTransactionsFoundStream;
  late final int _workchain;
  late final String _address;
  late final String _publicKey;
  late final WalletType _walletType;
  late final TonWalletDetails _details;
  late ContractState _contractState;
  late List<PendingTransaction> _pendingTransactions;
  late PollingMethod _pollingMethod;
  late List<MultisigPendingTransaction> _unconfirmedTransactions;

  /// Triggers subscribers when [_updateData] completes
  final _fieldsUpdateController = StreamController<void>.broadcast();
  late List<String>? _custodians;

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

  Transport get transport => _transport;

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

  ContractState get contractState => _contractState;

  Future<ContractState> get __contractState async {
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

  List<PendingTransaction> get pendingTransactions => _pendingTransactions;

  Future<List<PendingTransaction>> get __pendingTransactions async {
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

  PollingMethod get pollingMethod => _pollingMethod;

  Future<PollingMethod> get __pollingMethod async {
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

  List<MultisigPendingTransaction> get unconfirmedTransactions => _unconfirmedTransactions;

  Future<List<MultisigPendingTransaction>> get __unconfirmedTransactions async {
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

  List<String>? get custodians => _custodians;

  Stream<void> get fieldUpdatesController => _fieldsUpdateController.stream;

  Future<List<String>?> get __custodians async {
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

    final unsignedMessage = await UnsignedMessage.create(toPtrFromAddress(result as String));

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

    final unsignedMessage = await UnsignedMessage.create(toPtrFromAddress(result as String));

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

    await _updateData();

    final unsignedMessage = await UnsignedMessage.create(toPtrFromAddress(result as String));

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

    final unsignedMessage = await UnsignedMessage.create(toPtrFromAddress(result as String));

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

  Future<PendingTransaction> send(SignedMessage signedMessage) async {
    final signedMessageStr = jsonEncode(signedMessage);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_send(
            port,
            ptr,
            signedMessageStr.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as Map<String, dynamic>;
    final pendingTransaction = PendingTransaction.fromJson(json);

    return pendingTransaction;
  }

  Future<void> refresh() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_refresh(
            port,
            ptr,
          ),
    );

    await _updateData();
  }

  Future<void> preloadTransactions(String fromLt) async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_preload_transactions(
            port,
            ptr,
            fromLt.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();
  }

  Future<void> handleBlock(String block) async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_ton_wallet_handle_block(
            port,
            ptr,
            block.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();
  }

  Future<void> dispose() async {
    _onMessageSentPort.close();
    _onMessageExpiredPort.close();
    _onStateChangedPort.close();
    _onTransactionsFoundPort.close();
    _fieldsUpdateController.close();
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

          return result;
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

          return result;
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

          return result;
        },
      );

  Future<void> _updateData() async {
    _contractState = await __contractState;
    _pendingTransactions = await __pendingTransactions;
    _pollingMethod = await __pollingMethod;
    _unconfirmedTransactions = await __unconfirmedTransactions;
    _custodians = await __custodians;

    _fieldsUpdateController.add(null);
  }

  Future<void> _initialize(Future<dynamic> Function() subscribe) async {
    onMessageSentStream = _onMessageSentPort.cast<String>().map((e) {
      final json = jsonDecode(e) as List<dynamic>;

      final pendingTransactionJson = json.first as Map<String, dynamic>;
      final pendingTransaction = PendingTransaction.fromJson(pendingTransactionJson);
      final transactionJson = json.last as Map<String, dynamic>?;
      final transaction = transactionJson != null ? Transaction.fromJson(transactionJson) : null;

      return Tuple2(pendingTransaction, transaction);
    }).asBroadcastStream(onCancel: (subscription) => subscription.cancel());

    onMessageExpiredStream = _onMessageExpiredPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;

      final pendingTransaction = PendingTransaction.fromJson(json);

      return pendingTransaction;
    }).asBroadcastStream(onCancel: (subscription) => subscription.cancel());

    onStateChangedStream = _onStateChangedPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;

      final contractState = ContractState.fromJson(json);

      return contractState;
    }).asBroadcastStream(onCancel: (subscription) => subscription.cancel());

    onTransactionsFoundStream = _onTransactionsFoundPort.cast<String>().map((e) {
      final json = jsonDecode(e) as List<dynamic>;

      final transactionsJson = json.first as List<dynamic>;
      final transactions = transactionsJson
          .cast<Map<String, dynamic>>()
          .map(
            (e) => TransactionWithData<TransactionAdditionalInfo?>.fromJson(
              e,
              (json) => json != null
                  ? TransactionAdditionalInfo.fromJson(json as Map<String, dynamic>)
                  : null,
            ),
          )
          .toList();
      final batchInfoJson = json.last as Map<String, dynamic>;
      final batchInfo = TransactionsBatchInfo.fromJson(batchInfoJson);

      return Tuple2(transactions, batchInfo);
    }).asBroadcastStream(onCancel: (subscription) => subscription.cancel());

    _ptr = toPtrFromAddress(await subscribe() as String);

    _nativeFinalizer.attach(this, _ptr);

    _workchain = await __workchain;
    _address = await __address;
    _publicKey = await __publicKey;
    _walletType = await __walletType;
    _details = await __details;

    await _updateData();
  }
}
