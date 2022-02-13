import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart';

import '../../bindings.dart';
import '../../constants.dart';
import '../../ffi_utils.dart';
import '../../models/pointed.dart';
import '../../transport/transport.dart';
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
  late final Stream<OnBalanceChangedPayload> onBalanceChangedStream;
  late final Stream<OnTokenWalletTransactionsFoundPayload> onTransactionsFoundStream;
  late final StreamSubscription _onTransactionsFoundSubscription;
  late final String owner;
  late final String address;
  late final Symbol symbol;
  late final TokenWalletVersion version;
  final _transactionsSubject = BehaviorSubject<List<TokenWalletTransactionWithData>>.seeded([]);

  TokenWallet._();

  static Future<TokenWallet> subscribe({
    required Transport transport,
    required String owner,
    required String rootTokenContract,
  }) async {
    final tokenWallet = TokenWallet._();
    await tokenWallet._initialize(
      transport: transport,
      owner: owner,
      rootTokenContract: rootTokenContract,
    );
    return tokenWallet;
  }

  Stream<List<TokenWalletTransactionWithData>> get transactionsStream => _transactionsSubject.stream;

  Future<String> get _owner async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_token_wallet_owner(
        port,
        ptr,
      ),
    );

    final owner = cStringToDart(result);

    return owner;
  }

  Future<String> get _address async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_token_wallet_address(
        port,
        ptr,
      ),
    );

    final address = cStringToDart(result);

    return address;
  }

  Future<Symbol> get _symbol async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_token_wallet_symbol(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final symbol = Symbol.fromJson(json);

    return symbol;
  }

  Future<TokenWalletVersion> get _version async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_token_wallet_version(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string);
    final version = TokenWalletVersion.values.firstWhere((e) => describeEnum(e).pascalCase == json);

    return version;
  }

  Future<String> get balance async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_token_wallet_balance(
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
      (port) => bindings().get_token_wallet_contract_state(
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
      (port) => bindings().token_wallet_prepare_transfer(
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
      (port) => bindings().token_wallet_refresh(
        port,
        ptr,
      ),
    );
  }

  Future<void> preloadTransactions(TransactionId from) async {
    final ptr = await clonePtr();

    final fromStr = jsonEncode(from);

    await executeAsync(
      (port) => bindings().token_wallet_preload_transactions(
        port,
        ptr,
        fromStr.toNativeUtf8().cast<Int8>(),
      ),
    );
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Token wallet use after free');

        final ptr = bindings().clone_token_wallet_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Token wallet use after free');

        _onTransactionsFoundSubscription.cancel();

        _transactionsSubject.close();

        _onBalanceChangedPort.close();
        _onTransactionsFoundPort.close();

        bindings().free_token_wallet_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _initialize({
    required Transport transport,
    required String owner,
    required String rootTokenContract,
  }) async {
    final transportPtr = await transport.clonePtr();

    final transportType = transport.connectionData.type;

    final result = await executeAsync(
      (port) => bindings().token_wallet_subscribe(
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

    onBalanceChangedStream = _onBalanceChangedPort.asBroadcastStream().cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnBalanceChangedPayload.fromJson(json);
      return payload;
    });

    onTransactionsFoundStream = _onTransactionsFoundPort.asBroadcastStream().cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnTokenWalletTransactionsFoundPayload.fromJson(json);
      return payload;
    });

    _onTransactionsFoundSubscription = onTransactionsFoundStream.listen(_onTransactionsFoundListener);

    this.owner = await _owner;
    address = await _address;
    symbol = await _symbol;
    version = await _version;

    _refreshCycle();
  }

  void _onTransactionsFoundListener(OnTokenWalletTransactionsFoundPayload value) {
    final transactions = [
      ..._transactionsSubject.value,
      ...value.transactions,
    ]..sort();

    _transactionsSubject.add(transactions);
  }

  Future<void> _refreshCycle() async {
    while (_ptr != null) {
      try {
        await refresh();

        await Future.delayed(kRefreshPeriod);
      } catch (err, st) {
        nekotonErrorsSubject.add(Tuple2(err, st));
      }
    }
  }
}
