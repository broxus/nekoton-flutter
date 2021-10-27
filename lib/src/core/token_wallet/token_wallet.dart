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
import '../models/expiration.dart';
import '../models/native_unsigned_message.dart';
import '../models/pending_transaction.dart';
import '../models/polling_method.dart';
import '../models/subscription_handler_message.dart';
import '../models/transaction_id.dart';
import '../models/unsigned_message.dart';
import '../ton_wallet/ton_wallet.dart';
import 'models/native_token_wallet.dart';
import 'models/on_balance_changed_payload.dart';
import 'models/on_token_wallet_transactions_found_payload.dart';
import 'models/symbol.dart';
import 'models/token_wallet_transaction_with_data.dart';
import 'models/token_wallet_version.dart';

class TokenWallet implements Comparable<TokenWallet> {
  final _receivePort = ReceivePort();
  late final GqlTransport _transport;
  late final NativeTokenWallet _nativeTokenWallet;
  late final TonWallet _tonWallet;
  late final StreamSubscription _subscription;
  late final Timer _timer;
  late final String owner;
  late final String address;
  late final Symbol symbol;
  late final TokenWalletVersion version;
  late final String ownerPublicKey;
  final _onBalanceChangedSubject = BehaviorSubject<String>();
  final _onTransactionsFoundSubject = BehaviorSubject<List<TokenWalletTransactionWithData>>.seeded([]);

  TokenWallet._();

  static Future<TokenWallet> subscribe({
    required GqlTransport transport,
    required TonWallet tonWallet,
    required String rootTokenContract,
  }) async {
    final tokenWallet = TokenWallet._();
    await tokenWallet._initialize(
      transport: transport,
      tonWallet: tonWallet,
      rootTokenContract: rootTokenContract,
    );
    return tokenWallet;
  }

  Stream<String> get onBalanceChangedStream => _onBalanceChangedSubject.stream;

  Stream<List<TokenWalletTransactionWithData>> get onTransactionsFoundStream => _onTransactionsFoundSubject.stream;

  Future<String> get _owner async {
    final result = await _nativeTokenWallet.use(
      (ptr) async => proceedAsync(
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
      (ptr) async => proceedAsync(
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
      (ptr) async => proceedAsync(
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
      (ptr) async => proceedAsync(
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
      (ptr) async => proceedAsync(
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
      (ptr) async => proceedAsync(
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

  Future<ContractState> get ownerContractState async => _tonWallet.contractState;

  Future<UnsignedMessage> prepareDeploy(Expiration expiration) async {
    final expirationStr = jsonEncode(expiration);

    final result = await _nativeTokenWallet.use(
      (ptr) async => _tonWallet.nativeTonWallet.use(
        (nativeTonWalletPtr) async => _transport.nativeGqlTransport.use(
          (nativeGqlTransportPtr) async => proceedAsync(
            (port) => nativeLibraryInstance.bindings.token_wallet_prepare_deploy(
              port,
              ptr,
              nativeTonWalletPtr,
              nativeGqlTransportPtr,
              expirationStr.toNativeUtf8().cast<Int8>(),
            ),
          ),
        ),
      ),
    );

    final ptr = Pointer.fromAddress(result).cast<Void>();
    final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
    final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

    return unsignedMessage;
  }

  Future<UnsignedMessage> prepareTransfer({
    required Expiration expiration,
    required String destination,
    required String tokens,
    required bool notifyReceiver,
  }) async {
    final expirationStr = jsonEncode(expiration);

    final result = await _nativeTokenWallet.use(
      (ptr) async => _tonWallet.nativeTonWallet.use(
        (nativeTonWalletPtr) async => _transport.nativeGqlTransport.use(
          (nativeGqlTransportPtr) async => proceedAsync(
            (port) => nativeLibraryInstance.bindings.token_wallet_prepare_transfer(
              port,
              ptr,
              nativeTonWalletPtr,
              nativeGqlTransportPtr,
              expirationStr.toNativeUtf8().cast<Int8>(),
              destination.toNativeUtf8().cast<Int8>(),
              tokens.toNativeUtf8().cast<Int8>(),
              notifyReceiver ? 1 : 0,
            ),
          ),
        ),
      ),
    );

    final ptr = Pointer.fromAddress(result).cast<Void>();
    final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
    final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

    return unsignedMessage;
  }

  Future<int> estimateFees(UnsignedMessage message) async => _tonWallet.estimateFees(message);

  Future<PendingTransaction> send({
    required UnsignedMessage message,
    required String password,
  }) async {
    final currentBlockId = await _transport.getLatestBlockId(address);

    final result = await _tonWallet.send(
      message: message,
      password: password,
    );

    _internalRefresh(currentBlockId);

    return result;
  }

  Future<void> refresh() async => _nativeTokenWallet.use(
        (ptr) async => proceedAsync(
          (port) => nativeLibraryInstance.bindings.token_wallet_refresh(
            port,
            ptr,
          ),
        ),
      );

  Future<void> preloadTransactions(TransactionId from) async {
    final fromStr = jsonEncode(from);

    await _nativeTokenWallet.use(
      (ptr) async => proceedAsync(
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

    _onBalanceChangedSubject.close();
    _onTransactionsFoundSubject.close();

    _receivePort.close();

    return _nativeTokenWallet.free();
  }

  Future<void> _handleBlock(String id) async => _nativeTokenWallet.use(
        (ptr) async => _transport.nativeGqlTransport.use(
          (nativeGqlTransportPtr) async => proceedAsync(
            (port) => nativeLibraryInstance.bindings.token_wallet_handle_block(
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
        final nextBlockId = await _transport.waitForNextBlockId(
          currentBlockId: currentBlockId,
          address: address,
        );

        await _handleBlock(nextBlockId);
        await refresh();

        if (await _tonWallet.pollingMethod == PollingMethod.manual) {
          break;
        }
      } catch (err, st) {
        nekotonLogger?.e(err, err, st);
      }
    }
  }

  Future<void> _initialize({
    required GqlTransport transport,
    required TonWallet tonWallet,
    required String rootTokenContract,
  }) async {
    _transport = transport;
    _tonWallet = tonWallet;
    _subscription = _receivePort.listen(_subscriptionListener);

    final result = await _transport.nativeGqlTransport.use(
      (ptr) async => proceedAsync(
        (port) => nativeLibraryInstance.bindings.token_wallet_subscribe(
          port,
          _receivePort.sendPort.nativePort,
          ptr,
          _tonWallet.address.toNativeUtf8().cast<Int8>(),
          rootTokenContract.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );
    final ptr = Pointer.fromAddress(result).cast<Void>();

    _nativeTokenWallet = NativeTokenWallet(ptr);

    owner = await _owner;
    address = await _address;
    symbol = await _symbol;
    version = await _version;
    ownerPublicKey = tonWallet.publicKey;

    _timer = Timer.periodic(
      kGqlRefreshPeriod,
      _refreshTimer,
    );
  }

  Future<void> _subscriptionListener(dynamic data) async {
    try {
      if (data is! String) {
        return;
      }

      final json = jsonDecode(data) as Map<String, dynamic>;
      final message = SubscriptionHandlerMessage.fromJson(json);

      switch (message.event) {
        case 'on_balance_changed':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnBalanceChangedPayload.fromJson(json);

          final balance = payload.balance;

          _onBalanceChangedSubject.add(balance);
          break;
        case 'on_transactions_found':
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnTokenWalletTransactionsFoundPayload.fromJson(json);

          final transactions = [..._onTransactionsFoundSubject.value, ...payload.transactions]
            ..sort((a, b) => b.transaction.createdAt.compareTo(a.transaction.createdAt));

          _onTransactionsFoundSubject.add(transactions);
          break;
      }
    } catch (err, st) {
      nekotonLogger?.e(err, err, st);
    }
  }

  Future<void> _refreshTimer(Timer timer) async {
    try {
      await refresh();
    } catch (err, st) {
      nekotonLogger?.e(err, err, st);
    }
  }

  @override
  int compareTo(TokenWallet other) => symbol.name.compareTo(other.symbol.name);
}

Future<bool> checkTokenWalletValidity({
  required GqlTransport transport,
  required String owner,
  required String rootTokenContract,
}) async {
  final receivePort = ReceivePort();

  try {
    final result = await transport.nativeGqlTransport.use(
      (ptr) async => proceedAsync(
        (port) => nativeLibraryInstance.bindings.token_wallet_subscribe(
          port,
          receivePort.sendPort.nativePort,
          ptr,
          owner.toNativeUtf8().cast<Int8>(),
          rootTokenContract.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );
    final ptr = Pointer.fromAddress(result).cast<Void>();

    await proceedAsync(
      (port) => nativeLibraryInstance.bindings.free_token_wallet(
        port,
        ptr,
      ),
    );

    return true;
  } catch (_) {
    return false;
  }
}
