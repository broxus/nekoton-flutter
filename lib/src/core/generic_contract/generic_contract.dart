import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/contract_subscription/contract_subscription.dart';
import 'package:nekoton_flutter/src/core/generic_contract/models/transaction_execution_options.dart';
import 'package:nekoton_flutter/src/core/models/contract_state.dart';
import 'package:nekoton_flutter/src/core/models/on_message_expired_payload.dart';
import 'package:nekoton_flutter/src/core/models/on_message_sent_payload.dart';
import 'package:nekoton_flutter/src/core/models/on_state_changed_payload.dart';
import 'package:nekoton_flutter/src/core/models/on_transactions_found_payload.dart';
import 'package:nekoton_flutter/src/core/models/pending_transaction.dart';
import 'package:nekoton_flutter/src/core/models/polling_method.dart';
import 'package:nekoton_flutter/src/core/models/transaction.dart';
import 'package:nekoton_flutter/src/core/utils.dart';
import 'package:nekoton_flutter/src/crypto/models/signed_message.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_generic_contract_free_ptr);

class GenericContract extends ContractSubscription implements Finalizable {
  late final Pointer<Void> _ptr;
  final Transport _transport;
  final _onMessageSentPort = ReceivePort();
  final _onMessageExpiredPort = ReceivePort();
  final _onStateChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  late final Stream<OnMessageSentPayload> onMessageSentStream;
  late final Stream<OnMessageExpiredPayload> onMessageExpiredStream;
  late final Stream<OnStateChangedPayload> onStateChangedStream;
  late final Stream<OnTransactionsFoundPayload> onTransactionsFoundStream;
  late final String _address;

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

  @override
  Transport get transport => _transport;

  @override
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

  Future<ContractState> get contractState async {
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

  Future<List<PendingTransaction>> get pendingTransactions async {
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

  @override
  Future<PollingMethod> get pollingMethod async {
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

  Future<Transaction?> send(SignedMessage signedMessage) async {
    final pendingTransaction = await sendWithReliablePolling(() async {
      final signedMessageStr = jsonEncode(signedMessage);

      final result = await executeAsync(
        (port) => NekotonFlutter.instance().bindings.nt_generic_contract_send(
              port,
              ptr,
              signedMessageStr.toNativeUtf8().cast<Char>(),
            ),
      );

      final json = result as Map<String, dynamic>;
      final pendingTransaction = PendingTransaction.fromJson(json);

      return pendingTransaction;
    });

    final transaction = await onMessageSentStream
        .firstWhere((e) => e.pendingTransaction == pendingTransaction)
        .then((v) => v.transaction)
        .timeout(pendingTransaction.expireAt.toTimeout());

    return transaction;
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

  @override
  Future<void> refresh() => executeAsync(
        (port) => NekotonFlutter.instance().bindings.nt_generic_contract_refresh(
              port,
              ptr,
            ),
      );

  Future<void> preloadTransactions(String fromLt) => executeAsync(
        (port) => NekotonFlutter.instance().bindings.nt_generic_contract_preload_transactions(
              port,
              ptr,
              fromLt.toNativeUtf8().cast<Char>(),
            ),
      );

  @override
  Future<void> handleBlock(String block) => executeAsync(
        (port) => NekotonFlutter.instance().bindings.nt_generic_contract_handle_block(
              port,
              ptr,
              block.toNativeUtf8().cast<Char>(),
            ),
      );

  Future<void> dispose() async {
    _onMessageSentPort.close();
    _onMessageExpiredPort.close();
    _onStateChangedPort.close();
    _onTransactionsFoundPort.close();
  }

  Future<void> _initialize({
    required String address,
    required bool preloadTransactions,
  }) async {
    onMessageSentStream = _onMessageSentPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnMessageSentPayload.fromJson(json);
      return payload;
    }).asBroadcastStream();

    onMessageExpiredStream = _onMessageExpiredPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnMessageExpiredPayload.fromJson(json);
      return payload;
    }).asBroadcastStream();

    onStateChangedStream = _onStateChangedPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnStateChangedPayload.fromJson(json);
      return payload;
    }).asBroadcastStream();

    onTransactionsFoundStream = _onTransactionsFoundPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnTransactionsFoundPayload.fromJson(json);
      return payload;
    }).asBroadcastStream();

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
  }
}
