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
import '../models/contract_state.dart';
import '../models/on_message_expired_payload.dart';
import '../models/on_message_sent_payload.dart';
import '../models/on_state_changed_payload.dart';
import '../models/on_transactions_found_payload.dart';
import '../models/pending_transaction.dart';
import '../models/polling_method.dart';
import '../models/transaction.dart';
import '../models/transaction_id.dart';
import '../unsigned_message.dart';
import 'models/transaction_execution_options.dart';

class GenericContract implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;
  final _onMessageSentPort = ReceivePort();
  final _onMessageExpiredPort = ReceivePort();
  final _onStateChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  final _pendingTransactionsSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);
  late final Stream<OnMessageSentPayload> onMessageSentStream;
  late final Stream<OnMessageExpiredPayload> onMessageExpiredStream;
  late final Stream<OnStateChangedPayload> onStateChangedStream;
  late final Stream<OnTransactionsFoundPayload> onTransactionsFoundStream;
  late final Stream<List<PendingTransaction>> pendingTransactionsStream;
  late final Transport _transport;
  late final CustomRestartableTimer _backgroundRefreshTimer;
  final _addressMemo = AsyncMemoizer<String>();

  GenericContract._();

  static Future<GenericContract> subscribe({
    required Transport transport,
    required String address,
  }) async {
    final instance = GenericContract._();
    await instance._initialize(
      transport: transport,
      address: address,
    );
    return instance;
  }

  Future<String> get address => _addressMemo.runOnce(() async {
        final ptr = await clonePtr();

        final result = await executeAsync(
          (port) => bindings().get_generic_contract_address(
            port,
            ptr,
          ),
        );

        final address = cStringToDart(result);

        return address;
      });

  Future<ContractState> get contractState async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_generic_contract_contract_state(
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
      (port) => bindings().get_generic_contract_pending_transactions(
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
      (port) => bindings().get_generic_contract_polling_method(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string);
    final pollingMethod = PollingMethod.values.firstWhere((e) => describeEnum(e) == json);

    return pollingMethod;
  }

  Future<String> estimateFees(UnsignedMessage message) async {
    final ptr = await clonePtr();
    final unsignedMessagePtr = await message.clonePtr();

    final result = await executeAsync(
      (port) => bindings().generic_contract_estimate_fees(
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
      (port) => bindings().generic_contract_send(
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

  Future<Transaction> executeTransactionLocally({
    required Keystore keystore,
    required UnsignedMessage message,
    required SignInput signInput,
    required TransactionExecutionOptions options,
  }) async {
    final ptr = await clonePtr();
    final keystorePtr = await keystore.clonePtr();
    final unsignedMessagePtr = await message.clonePtr();
    final signInputStr = jsonEncode(signInput);
    final optionsStr = jsonEncode(options);

    final result = await executeAsync(
      (port) => bindings().generic_contract_execute_transaction_locally(
        port,
        ptr,
        keystorePtr,
        unsignedMessagePtr,
        signInputStr.toNativeUtf8().cast<Int8>(),
        optionsStr.toNativeUtf8().cast<Int8>(),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final transaction = Transaction.fromJson(json);

    return transaction;
  }

  Future<void> refresh() async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => bindings().generic_contract_refresh(
        port,
        ptr,
      ),
    );

    _pendingTransactionsSubject.add(await pendingTransactions);
  }

  Future<void> preloadTransactions(TransactionId from) async {
    final ptr = await clonePtr();
    final fromStr = jsonEncode(from);

    await executeAsync(
      (port) => bindings().generic_contract_preload_transactions(
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
      (port) => bindings().generic_contract_handle_block(
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
        if (_ptr == null) throw Exception('Generic contract use after free');

        final ptr = bindings().clone_generic_contract_ptr(
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

        _backgroundRefreshTimer.cancel();

        bindings().free_generic_contract_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _initialize({
    required Transport transport,
    required String address,
  }) =>
      _lock.synchronized(() async {
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
          final payload = OnTransactionsFoundPayload.fromJson(json);
          return payload;
        }).shareValue();

        pendingTransactionsStream = _pendingTransactionsSubject.stream;

        _transport = transport;

        final transportPtr = await transport.clonePtr();
        final transportType = transport.connectionData.type;

        final result = await executeAsync(
          (port) => bindings().generic_contract_subscribe(
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

        _backgroundRefreshTimer = CustomRestartableTimer(Duration.zero, _backgroundRefreshTimerCallback);
      });

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
