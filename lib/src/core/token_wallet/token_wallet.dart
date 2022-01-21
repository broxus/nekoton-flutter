import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';

import '../../constants.dart';
import '../../ffi_utils.dart';
import '../../nekoton.dart';
import '../../transport/gql_transport.dart';
import '../models/contract_state.dart';
import '../models/internal_message.dart';
import '../models/subscription_handler_message.dart';
import '../models/transaction_id.dart';
import 'models/native_token_wallet.dart';
import 'models/on_balance_changed_payload.dart';
import 'models/on_token_wallet_transactions_found_payload.dart';
import 'models/symbol.dart';
import 'models/token_wallet_transaction_with_data.dart';
import 'models/token_wallet_version.dart';

class TokenWallet {
  final _receivePort = ReceivePort();
  late final GqlTransport _transport;
  late final NativeTokenWallet _nativeTokenWallet;
  late final StreamSubscription _subscription;
  late final StreamSubscription _onTransactionsFoundSubscription;
  late final Timer _timer;
  late final String owner;
  late final String address;
  late final Symbol symbol;
  late final TokenWalletVersion version;
  final _onBalanceChangedSubject = PublishSubject<String>();
  final _onTransactionsFoundSubject = PublishSubject<OnTokenWalletTransactionsFoundPayload>();
  final _transactionsSubject = BehaviorSubject<List<TokenWalletTransactionWithData>>.seeded([]);

  TokenWallet._();

  static Future<TokenWallet> subscribe({
    required GqlTransport transport,
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

  Stream<String> get onBalanceChangedStream => _onBalanceChangedSubject.stream;

  Stream<OnTokenWalletTransactionsFoundPayload> get onTransactionsFoundStream => _onTransactionsFoundSubject.stream;

  Stream<List<TokenWalletTransactionWithData>> get transactionsStream => _transactionsSubject.stream;

  Future<String> get _owner async {
    final result = await _nativeTokenWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_token_wallet_owner(
          port,
          ptr,
        ),
      ),
    );
    final owner = cStringToDart(result);

    return owner;
  }

  Future<String> get _address async {
    final result = await _nativeTokenWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_token_wallet_address(
          port,
          ptr,
        ),
      ),
    );
    final address = cStringToDart(result);

    return address;
  }

  Future<Symbol> get _symbol async {
    final result = await _nativeTokenWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_token_wallet_symbol(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final symbol = Symbol.fromJson(json);

    return symbol;
  }

  Future<TokenWalletVersion> get _version async {
    final result = await _nativeTokenWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_token_wallet_version(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string);
    final version = TokenWalletVersion.values.firstWhere((e) => describeEnum(e).pascalCase == json);

    return version;
  }

  Future<String> get balance async {
    final result = await _nativeTokenWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_token_wallet_balance(
          port,
          ptr,
        ),
      ),
    );
    final balance = cStringToDart(result);

    return balance;
  }

  Future<ContractState> get contractState async {
    final result = await _nativeTokenWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_token_wallet_contract_state(
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

  Future<InternalMessage> prepareTransfer({
    required String destination,
    required String tokens,
    required bool notifyReceiver,
    String? payload,
  }) async {
    final result = await _nativeTokenWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.token_wallet_prepare_transfer(
          port,
          ptr,
          destination.toNativeUtf8().cast<Int8>(),
          tokens.toNativeUtf8().cast<Int8>(),
          notifyReceiver ? 1 : 0,
          payload?.toNativeUtf8().cast<Int8>() ?? Pointer.fromAddress(0).cast<Int8>(),
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final internalMessage = InternalMessage.fromJson(json);

    return internalMessage;
  }

  Future<void> refresh() => _nativeTokenWallet.use(
        (ptr) => proceedAsync(
          (port) => nativeLibraryInstance.bindings.token_wallet_refresh(
            port,
            ptr,
          ),
        ),
      );

  Future<void> preloadTransactions(TransactionId from) async {
    final fromStr = jsonEncode(from);

    await _nativeTokenWallet.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.token_wallet_preload_transactions(
          port,
          ptr,
          fromStr.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );
  }

  Future<void> free() async {
    _timer.cancel();

    _subscription.cancel();
    _onTransactionsFoundSubscription.cancel();

    _onBalanceChangedSubject.close();
    _onTransactionsFoundSubject.close();
    _transactionsSubject.close();

    _receivePort.close();

    await _nativeTokenWallet.free();
  }

  Future<void> _initialize({
    required GqlTransport transport,
    required String owner,
    required String rootTokenContract,
  }) async {
    _transport = transport;
    _subscription = _receivePort.listen(_subscriptionListener);
    _onTransactionsFoundSubscription = _onTransactionsFoundSubject.listen(_onTransactionsFoundListener);

    final result = await _transport.nativeGqlTransport.use(
      (ptr) => proceedAsync(
        (port) => nativeLibraryInstance.bindings.token_wallet_subscribe(
          port,
          _receivePort.sendPort.nativePort,
          ptr,
          owner.toNativeUtf8().cast<Int8>(),
          rootTokenContract.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );
    final ptr = Pointer.fromAddress(result).cast<Void>();

    _nativeTokenWallet = NativeTokenWallet(ptr);

    this.owner = await _owner;
    address = await _address;
    symbol = await _symbol;
    version = await _version;

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
        case 'on_balance_changed':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnBalanceChangedPayload.fromJson(json);

          _onBalanceChangedSubject.add(payload.balance);
          break;
        case 'on_transactions_found':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnTokenWalletTransactionsFoundPayload.fromJson(json);

          _onTransactionsFoundSubject.add(payload);
          break;
      }
    } catch (err, st) {
      logger?.e(err, err, st);
    }
  }

  Future<void> _refreshTimer(Timer timer) async {
    try {
      if (_nativeTokenWallet.isNull) {
        timer.cancel();
        return;
      }

      await refresh();
    } catch (err, st) {
      logger?.e(err, err, st);
    }
  }

  void _onTransactionsFoundListener(OnTokenWalletTransactionsFoundPayload value) {
    final transactions = [..._transactionsSubject.value, ...value.transactions]
      ..sort((a, b) => b.transaction.createdAt.compareTo(a.transaction.createdAt));

    _transactionsSubject.add(transactions);
  }
}
