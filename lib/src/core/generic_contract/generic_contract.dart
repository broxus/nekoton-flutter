import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/generic_contract/models/transaction_execution_options.dart';
import 'package:nekoton_flutter/src/core/models/contract_state.dart';
import 'package:nekoton_flutter/src/core/models/pending_transaction.dart';
import 'package:nekoton_flutter/src/core/models/polling_method.dart';
import 'package:nekoton_flutter/src/core/models/transaction.dart';
import 'package:nekoton_flutter/src/core/models/transactions_batch_info.dart';
import 'package:nekoton_flutter/src/crypto/models/signed_message.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';
import 'package:tuple/tuple.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_generic_contract_free_ptr);

class GenericContract implements Finalizable {
  late final Pointer<Void> _ptr;
  final Transport _transport;
  final _onMessageSentPort = ReceivePort();
  final _onMessageExpiredPort = ReceivePort();
  final _onStateChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  late final Stream<Tuple2<PendingTransaction, Transaction?>> onMessageSentStream;
  late final Stream<PendingTransaction> onMessageExpiredStream;
  late final Stream<ContractState> onStateChangedStream;
  late final Stream<Tuple2<List<Transaction>, TransactionsBatchInfo>> onTransactionsFoundStream;
  late final String _address;
  late ContractState _contractState;
  late List<PendingTransaction> _pendingTransactions;
  late PollingMethod _pollingMethod;

  GenericContract._(this._transport);

  static Future<GenericContract> subscribe({
    required Transport transport,
    required String address,
    required bool preloadTransactions,
  }) async {
    final instance = GenericContract._(transport);
    await instance._initialize(
      address: address,
      preloadTransactions: preloadTransactions,
    );
    return instance;
  }

  Pointer<Void> get ptr => _ptr;

  Transport get transport => _transport;

  String get address => _address;

  Future<String> get __address async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_generic_contract_address(
            port,
            ptr,
          ),
    );

    final address = result as String;

    return address;
  }

  ContractState get contractState => _contractState;

  Future<ContractState> get __contractState async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_generic_contract_contract_state(
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
      (port) => NekotonFlutter.instance().bindings.nt_generic_contract_pending_transactions(
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
      (port) => NekotonFlutter.instance().bindings.nt_generic_contract_polling_method(
            port,
            ptr,
          ),
    );

    final json = result as String;
    final pollingMethod = PollingMethod.values.firstWhere((e) => e.toString() == json);

    return pollingMethod;
  }

  Future<String> estimateFees(SignedMessage signedMessage) async {
    final signedMessageStr = jsonEncode(signedMessage);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_generic_contract_estimate_fees(
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
      (port) => NekotonFlutter.instance().bindings.nt_generic_contract_send(
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

  Future<Transaction> executeTransactionLocally({
    required SignedMessage signedMessage,
    required TransactionExecutionOptions options,
  }) async {
    final signedMessageStr = jsonEncode(signedMessage);
    final optionsStr = jsonEncode(options);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_generic_contract_execute_transaction_locally(
            port,
            ptr,
            signedMessageStr.toNativeUtf8().cast<Char>(),
            optionsStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;
    final transaction = Transaction.fromJson(json);

    return transaction;
  }

  Future<void> refresh() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_generic_contract_refresh(
            port,
            ptr,
          ),
    );

    await _updateData();
  }

  Future<void> preloadTransactions(String fromLt) async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_generic_contract_preload_transactions(
            port,
            ptr,
            fromLt.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();
  }

  Future<void> handleBlock(String block) async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_generic_contract_handle_block(
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
  }

  Future<void> _updateData() async {
    _contractState = await __contractState;
    _pendingTransactions = await __pendingTransactions;
    _pollingMethod = await __pollingMethod;
  }

  Future<void> _initialize({
    required String address,
    required bool preloadTransactions,
  }) async {
    onMessageSentStream = _onMessageSentPort.cast<String>().map((e) {
      final json = jsonDecode(e) as List<dynamic>;

      final pendingTransactionJson = json.last as Map<String, dynamic>;
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
          .map((e) => Transaction.fromJson(e))
          .toList();
      final batchInfoJson = json.last as Map<String, dynamic>;
      final batchInfo = TransactionsBatchInfo.fromJson(batchInfoJson);

      return Tuple2(transactions, batchInfo);
    }).asBroadcastStream(onCancel: (subscription) => subscription.cancel());

    final transportPtr = _transport.ptr;
    final transportTypeStr = jsonEncode(_transport.type.toString());

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_generic_contract_subscribe(
            port,
            _onMessageSentPort.sendPort.nativePort,
            _onMessageExpiredPort.sendPort.nativePort,
            _onStateChangedPort.sendPort.nativePort,
            _onTransactionsFoundPort.sendPort.nativePort,
            transportPtr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
            address.toNativeUtf8().cast<Char>(),
            preloadTransactions ? 1 : 0,
          ),
    );

    _ptr = toPtrFromAddress(result as String);

    _nativeFinalizer.attach(this, _ptr);

    _address = await __address;

    await _updateData();
  }
}
