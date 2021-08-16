import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';

import '../../external/gql.dart';
import '../../ffi_utils.dart';
import '../../native_library.dart';
import '../models/contract_state.dart';
import '../models/expiration.dart';
import '../models/native_unsigned_message.dart';
import '../models/pending_transaction.dart';
import '../models/subscription_handler_message.dart';
import '../models/transaction_id.dart';
import '../models/unsigned_message.dart';
import '../ton_wallet/models/polling_method.dart';
import '../ton_wallet/ton_wallet.dart';
import 'models/native_token_wallet.dart';
import 'models/on_balance_changed_payload.dart';
import 'models/on_token_wallet_transactions_found_payload.dart';
import 'models/symbol.dart';
import 'models/token_wallet_transaction_with_data.dart';
import 'models/token_wallet_version.dart';

Future<TokenWallet> tokenWalletSubscribe({
  required TonWallet tonWallet,
  required String rootTokenContract,
  Logger? logger,
}) async {
  final tokenWallet = TokenWallet._();

  tokenWallet._logger = logger;

  tokenWallet._tonWallet = tonWallet;
  tokenWallet._subscription = tokenWallet._receivePort.listen(tokenWallet._subscriptionListener);
  tokenWallet._gql = await Gql.getInstance(logger: tokenWallet._logger);

  final tonWalletAddress = tokenWallet._tonWallet.address;
  final result = await proceedAsync((port) => tokenWallet._nativeLibrary.bindings.token_wallet_subscribe(
        port,
        tokenWallet._receivePort.sendPort.nativePort,
        tokenWallet._gql.nativeTransport.ptr!,
        tonWalletAddress.toNativeUtf8().cast<Int8>(),
        rootTokenContract.toNativeUtf8().cast<Int8>(),
      ));
  final ptr = Pointer.fromAddress(result).cast<Void>();

  tokenWallet._nativeTokenWallet = NativeTokenWallet(ptr);
  tokenWallet._timer = Timer.periodic(
    const Duration(seconds: 15),
    tokenWallet._refreshTimer,
  );
  tokenWallet.owner = await tokenWallet._owner;
  tokenWallet.address = await tokenWallet._address;
  tokenWallet.symbol = await tokenWallet._symbol;
  tokenWallet.version = await tokenWallet._version;
  tokenWallet.ownerPublicKey = tonWallet.publicKey;

  return tokenWallet;
}

Future<void> tokenWalletUnsubscribe(TokenWallet tokenWallet) async {
  await proceedAsync((port) => tokenWallet._nativeLibrary.bindings.token_wallet_unsubscribe(
        port,
        tokenWallet._nativeTokenWallet.ptr!,
      ));
  tokenWallet._nativeTokenWallet.ptr = null;
  tokenWallet._receivePort.close();
  tokenWallet._subscription.cancel();
  tokenWallet._timer.cancel();
  tokenWallet._onBalanceChangedSubject.close();
  tokenWallet._onTransactionsFoundSubject.close();
}

class TokenWallet {
  final _receivePort = ReceivePort();
  final _nativeLibrary = NativeLibrary.instance();
  late final Logger? _logger;
  late final Gql _gql;
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

  Stream<String> get onBalanceChangedStream => _onBalanceChangedSubject.stream;

  Stream<List<TokenWalletTransactionWithData>> get onTransactionsFoundStream => _onTransactionsFoundSubject.stream;

  Future<String> get _owner async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_token_wallet_owner(
          port,
          _nativeTokenWallet.ptr!,
        ));
    final owner = cStringToDart(result);

    return owner;
  }

  Future<String> get _address async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_token_wallet_address(
          port,
          _nativeTokenWallet.ptr!,
        ));
    final address = cStringToDart(result);

    return address;
  }

  Future<Symbol> get _symbol async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_token_wallet_symbol(
          port,
          _nativeTokenWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final symbol = Symbol.fromJson(json);

    return symbol;
  }

  Future<TokenWalletVersion> get _version async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_token_wallet_version(
          port,
          _nativeTokenWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string);
    final version = TokenWalletVersion.values.firstWhere((e) => describeEnum(e).pascalCase == json);

    return version;
  }

  Future<String> get balance async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_token_wallet_balance(
          port,
          _nativeTokenWallet.ptr!,
        ));
    final balance = cStringToDart(result);

    return balance;
  }

  Future<ContractState> get contractState async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_token_wallet_contract_state(
          port,
          _nativeTokenWallet.ptr!,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final contractState = ContractState.fromJson(json);

    return contractState;
  }

  Future<ContractState> get ownerContractState async => _tonWallet.contractState;

  Future<UnsignedMessage> prepareDeploy(Expiration expiration) async {
    final expirationStr = jsonEncode(expiration.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.token_wallet_prepare_deploy(
          port,
          _nativeTokenWallet.ptr!,
          _tonWallet.nativeTonWallet.ptr!,
          _gql.nativeTransport.ptr!,
          expirationStr.toNativeUtf8().cast<Int8>(),
        ));

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
    final expirationStr = jsonEncode(expiration.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.token_wallet_prepare_transfer(
          port,
          _nativeTokenWallet.ptr!,
          _tonWallet.nativeTonWallet.ptr!,
          _gql.nativeTransport.ptr!,
          expirationStr.toNativeUtf8().cast<Int8>(),
          destination.toNativeUtf8().cast<Int8>(),
          tokens.toNativeUtf8().cast<Int8>(),
          notifyReceiver ? 1 : 0,
        ));

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
    final currentBlockId = await _gql.getLatestBlockId(address);

    final result = await _tonWallet.send(
      message: message,
      password: password,
    );

    _internalRefresh(currentBlockId);

    return result;
  }

  Future<void> refresh() async => proceedAsync((port) => _nativeLibrary.bindings.token_wallet_refresh(
        port,
        _nativeTokenWallet.ptr!,
      ));

  Future<void> preloadTransactions(TransactionId from) async {
    final fromStr = jsonEncode(from.toJson());

    await proceedAsync((port) => _nativeLibrary.bindings.token_wallet_preload_transactions(
          port,
          _nativeTokenWallet.ptr!,
          fromStr.toNativeUtf8().cast<Int8>(),
        ));
  }

  Future<void> _handleBlock(String id) async =>
      proceedAsync((port) => _nativeLibrary.bindings.token_wallet_handle_block(
            port,
            _nativeTokenWallet.ptr!,
            _gql.nativeTransport.ptr!,
            id.toNativeUtf8().cast<Int8>(),
          ));

  Future<void> _internalRefresh(String currentBlockId) async {
    for (var i = 0; 0 < 10; i++) {
      try {
        final nextBlockId = await _gql.waitForNextBlockId(
          currentBlockId: currentBlockId,
          address: address,
        );

        await _handleBlock(nextBlockId);
        await refresh();

        if (await _tonWallet.pollingMethod == PollingMethod.manual) {
          break;
        }
      } catch (err, st) {
        _logger?.e(err, err, st);
      }
    }
  }

  Future<void> _refreshTimer(Timer timer) async {
    try {
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
        case "on_balance_changed":
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnBalanceChangedPayload.fromJson(json);

          final balance = payload.balance;

          _onBalanceChangedSubject.add(balance);
          break;
        case "on_transactions_found":
          final json = jsonDecode(message.payload) as Map<String, dynamic>;
          final payload = OnTokenWalletTransactionsFoundPayload.fromJson(json);

          final transactions = [..._onTransactionsFoundSubject.value, ...payload.transactions]
            ..sort((a, b) => b.transaction.createdAt.compareTo(a.transaction.createdAt));

          _onTransactionsFoundSubject.add(transactions);
          break;
      }
    } catch (err, st) {
      _logger?.e(err, err, st);
    }
  }

  @override
  String toString() => 'TokenWallet(${_nativeTokenWallet.ptr?.address})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      other is TokenWallet && other._nativeTokenWallet.ptr?.address == _nativeTokenWallet.ptr?.address;

  @override
  int get hashCode => _nativeTokenWallet.ptr?.address ?? 0;
}