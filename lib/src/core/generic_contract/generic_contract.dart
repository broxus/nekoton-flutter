import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../constants.dart';
import '../../core/keystore/keystore.dart';
import '../../crypto/models/sign_input.dart';
import '../../ffi_utils.dart';
import '../../nekoton.dart';
import '../../provider/models/contract_state_changed_event.dart';
import '../../provider/models/transactions_found_event.dart';
import '../../provider/provider_events.dart';
import '../../transport/gql_transport.dart';
import '../models/contract_state.dart';
import '../models/on_message_expired_payload.dart';
import '../models/on_message_sent_payload.dart';
import '../models/on_state_changed_payload.dart';
import '../models/on_transactions_found_payload.dart';
import '../models/pending_transaction.dart';
import '../models/polling_method.dart';
import '../models/subscription_handler_message.dart';
import '../models/transaction.dart';
import '../models/transaction_id.dart';
import '../models/unsigned_message.dart';
import 'models/native_generic_contract.dart';
import 'models/transaction_execution_options.dart';

class GenericContract {
  final _receivePort = ReceivePort();
  late final GqlTransport _transport;
  late final Keystore _keystore;
  late final NativeGenericContract _nativeGenericContract;
  late final StreamSubscription _subscription;
  late final StreamSubscription _onMessageSentSubscription;
  late final StreamSubscription _onContractStateChangedSubscription;
  late final StreamSubscription _onMessageExpiredSubscription;
  late final StreamSubscription _onTransactionsFoundSubscription;
  late final Timer _timer;
  late final String address;
  final _onMessageSentSubject = PublishSubject<OnMessageSentPayload>();
  final _onMessageExpiredSubject = PublishSubject<OnMessageExpiredPayload>();
  final _onStateChangedSubject = PublishSubject<OnStateChangedPayload>();
  final _onTransactionsFoundSubject = PublishSubject<OnTransactionsFoundPayload>();
  final _transactionsSubject = BehaviorSubject<List<Transaction>>.seeded([]);
  final _pendingTransactionsSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);
  final _expiredTransactionsSubject = BehaviorSubject<List<PendingTransaction>>.seeded([]);

  GenericContract._();

  static Future<GenericContract> subscribe({
    required GqlTransport transport,
    required String address,
  }) async {
    final genericContract = GenericContract._();
    await genericContract._initialize(
      transport: transport,
      address: address,
    );
    return genericContract;
  }

  Stream<OnMessageSentPayload> get onMessageSentStream => _onMessageSentSubject.stream;

  Stream<OnMessageExpiredPayload> get onMessageExpiredStream => _onMessageExpiredSubject.stream;

  Stream<OnStateChangedPayload> get onStateChangedStream => _onStateChangedSubject.stream;

  Stream<OnTransactionsFoundPayload> get onTransactionsFoundStream => _onTransactionsFoundSubject.stream;

  Stream<List<Transaction>> get transactionsStream => _transactionsSubject.stream;

  Stream<List<PendingTransaction>> get pendingTransactionsStream => _pendingTransactionsSubject.stream;

  Stream<List<PendingTransaction>> get expiredTransactionsStream => _expiredTransactionsSubject.stream;

  Future<String> get _address async {
    final result = await _nativeGenericContract.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_generic_contract_address(
          port,
          ptr,
        ),
      ),
    );
    final address = cStringToDart(result);

    return address;
  }

  Future<ContractState> get contractState async {
    final result = await _nativeGenericContract.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_generic_contract_contract_state(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final contractState = ContractState.fromJson(json);

    return contractState;
  }

  Future<List<PendingTransaction>> get pendingTransactions async {
    final result = await _nativeGenericContract.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_generic_contract_pending_transactions(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final jsonList = json.cast<Map<String, dynamic>>();
    final pendingTransactions = jsonList.map((e) => PendingTransaction.fromJson(e)).toList();

    return pendingTransactions;
  }

  Future<PendingTransaction> send({
    required UnsignedMessage message,
    required SignInput signInput,
  }) async {
    final signInputStr = signInput.when(
      derivedKeySignParams: (derivedKeySignParams) => jsonEncode(derivedKeySignParams),
      encryptedKeyPassword: (encryptedKeyPassword) => jsonEncode(encryptedKeyPassword),
    );

    final currentBlockId = await _transport.getLatestBlockId(address);

    final result = await _nativeGenericContract.use(
      (ptr) => _keystore.nativeKeystore.use(
        (nativeKeystorePtr) => message.nativeUnsignedMessage.use(
          (nativeUnsignedMessagePtr) => proceedAsync(
            (port) => nativeLibraryInstance.bindings.generic_contract_send(
              port,
              ptr,
              nativeKeystorePtr,
              nativeUnsignedMessagePtr,
              signInputStr.toNativeUtf8().cast<Int8>(),
            ),
          ),
        ),
      ),
    );
    await message.nativeUnsignedMessage.free();

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final pendingTransaction = PendingTransaction.fromJson(json);

    final pending = [
      pendingTransaction,
      ..._pendingTransactionsSubject.value,
    ];

    _pendingTransactionsSubject.add(pending);

    _internalRefresh(currentBlockId);

    return pendingTransaction;
  }

  Future<void> refresh() => _nativeGenericContract.use(
        (ptr) => proceedAsync(
          (port) => nativeLibraryInstance.bindings.generic_contract_refresh(
            port,
            ptr,
          ),
        ),
      );

  Future<void> preloadTransactions(TransactionId from) async {
    final fromStr = jsonEncode(from);

    await _nativeGenericContract.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.generic_contract_preload_transactions(
          port,
          ptr,
          fromStr.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );
  }

  Future<int> estimateFees(UnsignedMessage message) => _nativeGenericContract.use(
        (ptr) => message.nativeUnsignedMessage.use(
          (nativeUnsignedMessagePtr) => proceedAsync(
            (port) => nativeLibraryInstance.bindings.generic_contract_estimate_fees(
              port,
              ptr,
              nativeUnsignedMessagePtr,
            ),
          ),
        ),
      );

  Future<Transaction> executeTransactionLocally({
    required UnsignedMessage message,
    required SignInput signInput,
    required TransactionExecutionOptions options,
  }) async {
    final signInputStr = signInput.when(
      derivedKeySignParams: (derivedKeySignParams) => jsonEncode(derivedKeySignParams),
      encryptedKeyPassword: (encryptedKeyPassword) => jsonEncode(encryptedKeyPassword),
    );

    final optionsStr = jsonEncode(options);

    final result = await _nativeGenericContract.use(
      (ptr) => _keystore.nativeKeystore.use(
        (nativeKeystorePtr) => message.nativeUnsignedMessage.use(
          (nativeUnsignedMessagePtr) => proceedAsync(
            (port) => nativeLibraryInstance.bindings.generic_contract_execute_transaction_locally(
              port,
              ptr,
              nativeKeystorePtr,
              nativeUnsignedMessagePtr,
              signInputStr.toNativeUtf8().cast<Int8>(),
              optionsStr.toNativeUtf8().cast<Int8>(),
            ),
          ),
        ),
      ),
    );
    await message.nativeUnsignedMessage.free();

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final transaction = Transaction.fromJson(json);

    return transaction;
  }

  Future<PollingMethod> get _pollingMethod async {
    final result = await _nativeGenericContract.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_generic_contract_polling_method(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string);
    final pollingMethod = PollingMethod.values.firstWhere((e) => describeEnum(e) == json);

    return pollingMethod;
  }

  Future<Transaction> waitForTransaction(PendingTransaction pendingTransaction) async => _onMessageSentSubject.stream
      .firstWhere((e) => e.pendingTransaction == pendingTransaction)
      .then((v) => v.transaction!);

  Future<void> free() async {
    _timer.cancel();

    _subscription.cancel();
    _onMessageSentSubscription.cancel();
    _onMessageExpiredSubscription.cancel();
    _onContractStateChangedSubscription.cancel();
    _onTransactionsFoundSubscription.cancel();

    _onMessageSentSubject.close();
    _onMessageExpiredSubject.close();
    _onStateChangedSubject.close();
    _onTransactionsFoundSubject.close();
    _transactionsSubject.close();
    _pendingTransactionsSubject.close();
    _expiredTransactionsSubject.close();

    _receivePort.close();

    await _nativeGenericContract.free();
  }

  Future<void> _handleBlock(String id) => _nativeGenericContract.use(
        (ptr) => _transport.nativeGqlTransport.use(
          (nativeGqlTransportPtr) => proceedAsync(
            (port) => nativeLibraryInstance.bindings.generic_contract_handle_block(
              port,
              ptr,
              nativeGqlTransportPtr,
              id.toNativeUtf8().cast<Int8>(),
            ),
          ),
        ),
      );

  Future<void> _internalRefresh(String currentBlockId) async {
    for (var i = 0; 0 < 10; i++) {
      try {
        if (_nativeGenericContract.isNull) break;

        final nextBlockId = await _transport.waitForNextBlockId(
          currentBlockId: currentBlockId,
          address: address,
        );

        await _handleBlock(nextBlockId);
        await refresh();

        if (await _pollingMethod == PollingMethod.manual) break;
      } catch (err, st) {
        logger?.e(err, err, st);
        break;
      }
    }
  }

  Future<void> _initialize({
    required GqlTransport transport,
    required String address,
  }) async {
    _transport = transport;
    _keystore = await Keystore.getInstance();
    _subscription = _receivePort.listen(_subscriptionListener);
    _onMessageSentSubscription = _onMessageSentSubject.listen(_onMessageSentListener);
    _onMessageExpiredSubscription = _onMessageExpiredSubject.listen(_onMessageExpiredListener);
    _onContractStateChangedSubscription = _onStateChangedSubject.listen(_onContractStateChangedListener);
    _onTransactionsFoundSubscription = _onTransactionsFoundSubject.listen(_onTransactionsFoundListener);

    final result = await _transport.nativeGqlTransport.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.generic_contract_subscribe(
          port,
          _receivePort.sendPort.nativePort,
          ptr,
          address.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );
    final ptr = Pointer.fromAddress(result).cast<Void>();

    _nativeGenericContract = NativeGenericContract(ptr);

    this.address = await _address;

    _timer = Timer.periodic(
      kGqlRefreshPeriod,
      _refreshTimer,
    );
  }

  Future<void> _subscriptionListener(dynamic data) async {
    try {
      if (data is! String) return;

      final json = jsonDecode(data) as Map<String, dynamic>;
      final message = SubscriptionHandlerMessage.fromJson(json);

      switch (message.event) {
        case 'on_message_sent':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnMessageSentPayload.fromJson(json);

          _onMessageSentSubject.add(payload);
          break;
        case 'on_message_expired':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnMessageExpiredPayload.fromJson(json);

          _onMessageExpiredSubject.add(payload);
          break;
        case 'on_state_changed':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnStateChangedPayload.fromJson(json);

          _onStateChangedSubject.add(payload);
          break;
        case 'on_transactions_found':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnTransactionsFoundPayload.fromJson(json);

          _onTransactionsFoundSubject.add(payload);
          break;
      }
    } catch (err, st) {
      logger?.e(err, err, st);
    }
  }

  Future<void> _refreshTimer(Timer timer) async {
    try {
      if (_nativeGenericContract.isNull) {
        timer.cancel();
        return;
      }

      if (await _pollingMethod == PollingMethod.reliable) return;

      await refresh();
    } catch (err, st) {
      logger?.e(err, err, st);
    }
  }

  void _onMessageSentListener(OnMessageSentPayload value) {
    final pending = [..._pendingTransactionsSubject.value.where((e) => e != value.pendingTransaction)];

    _pendingTransactionsSubject.add(pending);
  }

  void _onMessageExpiredListener(OnMessageExpiredPayload value) {
    final pending = [..._pendingTransactionsSubject.value.where((e) => e != value.pendingTransaction)];

    _pendingTransactionsSubject.add(pending);

    final expired = [..._expiredTransactionsSubject.value, value.pendingTransaction];

    _expiredTransactionsSubject.add(expired);
  }

  void _onContractStateChangedListener(OnStateChangedPayload value) {
    contractStateChangedSubject.add(
      ContractStateChangedEvent(
        address: address,
        state: value.newState,
      ),
    );
  }

  void _onTransactionsFoundListener(OnTransactionsFoundPayload value) {
    final transactions = [..._transactionsSubject.value, ...value.transactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _transactionsSubject.add(transactions);

    transactionsFoundSubject.add(
      TransactionsFoundEvent(
        address: address,
        transactions: value.transactions,
        info: value.batchInfo,
      ),
    );
  }
}
