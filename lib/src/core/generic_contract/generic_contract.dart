import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/on_message_expired_payload.dart';
import '../models/on_message_sent_payload.dart';
import '../models/polling_method.dart';
import '../../transport/gql_transport.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/keystore/keystore.dart';
import '../../ffi_utils.dart';
import '../../native_library.dart';
import '../keystore/models/key_store_entry.dart';
import '../models/contract_state.dart';
import '../models/on_state_changed_payload.dart';
import '../models/on_transactions_found_payload.dart';
import '../models/pending_transaction.dart';
import '../models/subscription_handler_message.dart';
import '../models/transaction.dart';
import '../models/transaction_id.dart';
import '../models/unsigned_message.dart';
import 'models/native_generic_contract.dart';
import 'models/transaction_execution_options.dart';

part 'free_generic_contract.dart';
part 'generic_contract_subscribe.dart';

class GenericContract {
  final _receivePort = ReceivePort();
  final _nativeLibrary = NativeLibrary.instance();
  late final Logger? _logger;
  late final GqlTransport _transport;
  late final Keystore _keystore;
  late final KeyStoreEntry? _entry;
  late final NativeGenericContract _nativeGenericContract;
  late final StreamSubscription _subscription;
  late final Timer _timer;
  late final String address;
  final _onMessageSentSubject = BehaviorSubject<Map<PendingTransaction, Transaction>>.seeded({});
  final _onMessageExpiredSubject = BehaviorSubject<List<Transaction>>.seeded([]);
  final _onStateChangedSubject = BehaviorSubject<ContractState>();
  final _onTransactionsFoundSubject = BehaviorSubject<List<Transaction>>.seeded([]);

  GenericContract._();

  Stream<List<Transaction>> get onMessageSentStream => _onMessageSentSubject.stream.transform<List<Transaction>>(
        StreamTransformer.fromHandlers(
          handleData: (Map<PendingTransaction, Transaction> data, EventSink<List<Transaction>> sink) => sink.add(
            data.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          ),
        ),
      );

  Stream<List<Transaction>> get onMessageExpiredStream => _onMessageExpiredSubject.stream;

  Stream<ContractState> get onStateChangedStream => _onStateChangedSubject.stream;

  Stream<List<Transaction>> get onTransactionsFoundStream => _onTransactionsFoundSubject.stream;

  Future<String> get _address async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_generic_contract_address(
          port,
          _nativeGenericContract.ptr!,
        ));
    final address = cStringToDart(result);

    return address;
  }

  Future<ContractState> get contractState async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_generic_contract_contract_state(
          port,
          _nativeGenericContract.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final contractState = ContractState.fromJson(json);

    return contractState;
  }

  Future<List<PendingTransaction>> get pendingTransactions async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_generic_contract_pending_transactions(
          port,
          _nativeGenericContract.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final jsonList = json.cast<Map<String, dynamic>>();
    final pendingTransactions = jsonList.map((e) => PendingTransaction.fromJson(e)).toList();

    return pendingTransactions;
  }

  Future<PendingTransaction> send({
    required UnsignedMessage message,
    required String password,
  }) async {
    if (_entry == null) {
      throw Exception();
    }

    final currentBlockId = await _transport.getLatestBlockId(address);
    final signInput = await _keystore.getSignInput(
      entry: _entry!,
      password: password,
    );
    final signInputStr = jsonEncode(signInput.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.generic_contract_send(
          port,
          _nativeGenericContract.ptr!,
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

  Future<void> refresh() async => proceedAsync((port) => _nativeLibrary.bindings.generic_contract_refresh(
        port,
        _nativeGenericContract.ptr!,
      ));

  Future<void> preloadTransactions(TransactionId from) async {
    final fromStr = jsonEncode(from.toJson());

    await proceedAsync((port) => _nativeLibrary.bindings.generic_contract_preload_transactions(
          port,
          _nativeGenericContract.ptr!,
          fromStr.toNativeUtf8().cast<Int8>(),
        ));
  }

  Future<int> estimateFees(UnsignedMessage message) async =>
      proceedAsync((port) => _nativeLibrary.bindings.generic_contract_estimate_fees(
            port,
            _nativeGenericContract.ptr!,
            message.nativeUnsignedMessage.ptr!,
          ));

  Future<Transaction> executeTransactionLocally({
    required UnsignedMessage message,
    required String password,
    required TransactionExecutionOptions options,
  }) async {
    if (_entry == null) {
      throw Exception();
    }

    final signInput = await _keystore.getSignInput(
      entry: _entry!,
      password: password,
    );
    final signInputStr = jsonEncode(signInput.toJson());
    final optionsStr = jsonEncode(options.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.generic_contract_execute_transaction_locally(
          port,
          _nativeGenericContract.ptr!,
          _keystore.nativeKeystore.ptr!,
          message.nativeUnsignedMessage.ptr!,
          signInputStr.toNativeUtf8().cast<Int8>(),
          optionsStr.toNativeUtf8().cast<Int8>(),
        ));
    message.nativeUnsignedMessage.ptr = null;

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final transaction = Transaction.fromJson(json);

    return transaction;
  }

  Future<PollingMethod> get _pollingMethod async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_generic_contract_polling_method(
          port,
          _nativeGenericContract.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string);
    final pollingMethod = PollingMethod.values.firstWhere((e) => describeEnum(e).pascalCase == json);

    return pollingMethod;
  }

  Future<void> _handleBlock(String id) async =>
      proceedAsync((port) => _nativeLibrary.bindings.generic_contract_handle_block(
            port,
            _nativeGenericContract.ptr!,
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

        if (await _pollingMethod == PollingMethod.manual) {
          break;
        }
      } catch (err, st) {
        _logger?.e(err, err, st);
      }
    }
  }

  Future<void> _refreshTimer(Timer timer) async {
    try {
      if (await _pollingMethod == PollingMethod.reliable) {
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
          final payload = OnTransactionsFoundPayload.fromJson(json);

          if (!payload.batchInfo.old) {
            final sent = {..._onMessageSentSubject.value};

            final list = <Transaction>[];

            for (final transaction in sent.values) {
              if (payload.transactions.firstWhereOrNull((e) => e == transaction) != null) {
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
          ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _onTransactionsFoundSubject.add(transactions);
          break;
      }
    } catch (err, st) {
      _logger?.e(err, err, st);
    }
  }

  @override
  String toString() => 'GenericContract(${_nativeGenericContract.ptr?.address})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      other is GenericContract && other._nativeGenericContract.ptr?.address == _nativeGenericContract.ptr?.address;

  @override
  int get hashCode => _nativeGenericContract.ptr?.address ?? 0;
}
