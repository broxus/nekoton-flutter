import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

import '../../bindings.dart';
import '../../constants.dart';
import '../../ffi_utils.dart';
import '../../models/pointed.dart';
import '../../transport/transport.dart';
import '../../utils.dart';
import '../models/contract_state.dart';
import '../models/internal_message.dart';
import '../models/transaction_id.dart';
import 'models/on_balance_changed_payload.dart';
import 'models/on_token_wallet_transactions_found_payload.dart';
import 'models/symbol.dart';
import 'models/token_wallet_transaction_with_data.dart';
import 'models/token_wallet_version.dart';

class TokenWallet implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;
  final _onBalanceChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  final _transactionsSubject = BehaviorSubject<List<TokenWalletTransactionWithData>>.seeded([]);
  late final Stream<String> balanceChangesStream;
  late final Stream<List<TokenWalletTransactionWithData>> transactionsStream = _transactionsSubject;
  late final Transport transport;
  late final CustomRestartableTimer _backgroundRefreshTimer;
  final _ownerMemo = AsyncMemoizer<String>();
  final _addressMemo = AsyncMemoizer<String>();
  final _symbolMemo = AsyncMemoizer<Symbol>();
  final _versionMemo = AsyncMemoizer<TokenWalletVersion>();

  TokenWallet._();

  static Future<TokenWallet> subscribe({
    required Transport transport,
    required String owner,
    required String rootTokenContract,
  }) async {
    final instance = TokenWallet._();
    await instance._initialize(
      transport: transport,
      owner: owner,
      rootTokenContract: rootTokenContract,
    );
    return instance;
  }

  Future<String> get owner => _ownerMemo.runOnce(() async {
        final ptr = await clonePtr();

        final result = await executeAsync(
          (port) => NekotonFlutter.bindings.get_token_wallet_owner(
            port,
            ptr,
          ),
        );

        final owner = cStringToDart(result);

        return owner;
      });

  Future<String> get address => _addressMemo.runOnce(() async {
        final ptr = await clonePtr();

        final result = await executeAsync(
          (port) => NekotonFlutter.bindings.get_token_wallet_address(
            port,
            ptr,
          ),
        );

        final address = cStringToDart(result);

        return address;
      });

  Future<Symbol> get symbol => _symbolMemo.runOnce(() async {
        final ptr = await clonePtr();

        final result = await executeAsync(
          (port) => NekotonFlutter.bindings.get_token_wallet_symbol(
            port,
            ptr,
          ),
        );

        final string = cStringToDart(result);
        final json = jsonDecode(string) as Map<String, dynamic>;
        final symbol = Symbol.fromJson(json);

        return symbol;
      });

  Future<TokenWalletVersion> get version => _versionMemo.runOnce(() async {
        final ptr = await clonePtr();

        final result = await executeAsync(
          (port) => NekotonFlutter.bindings.get_token_wallet_version(
            port,
            ptr,
          ),
        );

        final string = cStringToDart(result);
        final json = jsonDecode(string);
        final version = TokenWalletVersion.values.firstWhere((e) => describeEnum(e).pascalCase == json);

        return version;
      });

  Future<String> get balance async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.bindings.get_token_wallet_balance(
        port,
        ptr,
      ),
    );

    final balance = cStringToDart(result);

    return balance;
  }

  Future<ContractState> get contractState async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.bindings.get_token_wallet_contract_state(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final contractState = ContractState.fromJson(json);

    return contractState;
  }

  Future<InternalMessage> prepareTransfer({
    required String destination,
    required String tokens,
    required bool notifyReceiver,
    String? payload,
  }) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.bindings.token_wallet_prepare_transfer(
        port,
        ptr,
        destination.toNativeUtf8().cast<Int8>(),
        tokens.toNativeUtf8().cast<Int8>(),
        notifyReceiver ? 1 : 0,
        payload?.toNativeUtf8().cast<Int8>() ?? nullptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final internalMessage = InternalMessage.fromJson(json);

    return internalMessage;
  }

  Future<void> refresh() async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => NekotonFlutter.bindings.token_wallet_refresh(
        port,
        ptr,
      ),
    );
  }

  Future<void> preloadTransactions(TransactionId from) async {
    final ptr = await clonePtr();
    final fromStr = jsonEncode(from);

    await executeAsync(
      (port) => NekotonFlutter.bindings.token_wallet_preload_transactions(
        port,
        ptr,
        fromStr.toNativeUtf8().cast<Int8>(),
      ),
    );
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Token wallet use after free');

        final ptr = NekotonFlutter.bindings.clone_token_wallet_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) return;

        _onBalanceChangedPort.close();
        _onTransactionsFoundPort.close();

        _transactionsSubject.close();

        _backgroundRefreshTimer.cancel();

        NekotonFlutter.bindings.free_token_wallet_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _initialize({
    required Transport transport,
    required String owner,
    required String rootTokenContract,
  }) =>
      _lock.synchronized(() async {
        this.transport = transport;

        balanceChangesStream = _onBalanceChangedPort
            .cast<String>()
            .map((e) {
              final json = jsonDecode(e) as Map<String, dynamic>;
              final payload = OnBalanceChangedPayload.fromJson(json);
              return payload;
            })
            .map((event) => event.balance)
            .asBroadcastStream();

        _onTransactionsFoundPort.cast<String>().map((e) {
          final json = jsonDecode(e) as Map<String, dynamic>;
          final payload = OnTokenWalletTransactionsFoundPayload.fromJson(json);
          return payload;
        }).listen(
          (event) => _transactionsSubject.add(
            [
              ..._transactionsSubject.value,
              ...event.transactions,
            ]..sort((a, b) => a.transaction.compareTo(b.transaction)),
          ),
        );

        final transportPtr = await transport.clonePtr();
        final transportType = transport.connectionData.type;

        final result = await executeAsync(
          (port) => NekotonFlutter.bindings.token_wallet_subscribe(
            port,
            _onBalanceChangedPort.sendPort.nativePort,
            _onTransactionsFoundPort.sendPort.nativePort,
            transportPtr,
            transportType.index,
            owner.toNativeUtf8().cast<Int8>(),
            rootTokenContract.toNativeUtf8().cast<Int8>(),
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
      await refresh();

      _backgroundRefreshTimer.reset(kRefreshInterval);
    } catch (err, st) {
      NekotonFlutter.logger?.e('Token wallet background refresh', err, st);
      _backgroundRefreshTimer.reset(Duration.zero);
    }
  }
}
