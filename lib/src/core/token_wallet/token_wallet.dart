import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/contract_subscription/contract_subscription.dart';
import 'package:nekoton_flutter/src/core/models/contract_state.dart';
import 'package:nekoton_flutter/src/core/models/internal_message.dart';
import 'package:nekoton_flutter/src/core/models/polling_method.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/on_balance_changed_payload.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/on_token_wallet_transactions_found_payload.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/symbol.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/token_wallet_transaction_with_data.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/token_wallet_version.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';
import 'package:nekoton_flutter/src/utils.dart';
import 'package:rxdart/rxdart.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_token_wallet_free_ptr);

class TokenWallet extends ContractSubscription implements Finalizable {
  late final Pointer<Void> _ptr;
  final Transport _transport;
  final _onBalanceChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  late final Stream<OnBalanceChangedPayload> onBalanceChangedStream;
  late final Stream<OnTokenWalletTransactionsFoundPayload> _onTransactionsFoundStream;
  late final StreamSubscription<OnTokenWalletTransactionsFoundPayload>
      _onTransactionsFoundSubscription;
  final _transactionsSubject = BehaviorSubject<List<TokenWalletTransactionWithData>>.seeded([]);
  late final String _owner;
  late final String _address;
  late final Symbol _symbol;
  late final TokenWalletVersion _version;

  TokenWallet._(this._transport);

  static Future<TokenWallet> subscribe({
    required Transport transport,
    required String owner,
    required String rootTokenContract,
  }) async {
    final instance = TokenWallet._(transport);
    await instance._initialize(
      owner: owner,
      rootTokenContract: rootTokenContract,
    );
    return instance;
  }

  Pointer<Void> get ptr => _ptr;

  @override
  Transport get transport => _transport;

  Stream<List<TokenWalletTransactionWithData>> get transactionsStream =>
      _transactionsSubject.distinct((a, b) => listEquals(a, b));

  List<TokenWalletTransactionWithData> get transactions => _transactionsSubject.value;

  String get owner => _owner;

  Future<String> get __owner async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_owner(
            port,
            ptr,
          ),
    );

    final owner = result as String;

    return owner;
  }

  @override
  String get address => _address;

  Future<String> get __address async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_address(
            port,
            ptr,
          ),
    );

    final address = result as String;

    return address;
  }

  Symbol get symbol => _symbol;

  Future<Symbol> get __symbol async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_symbol(
            port,
            ptr,
          ),
    );

    final json = result as Map<String, dynamic>;
    final symbol = Symbol.fromJson(json);

    return symbol;
  }

  TokenWalletVersion get version => _version;

  Future<TokenWalletVersion> get __version async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_version(
            port,
            ptr,
          ),
    );

    final json = result as String;
    final version = TokenWalletVersion.values.firstWhere((e) => e.toString() == json);

    return version;
  }

  Future<String> get balance async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_balance(
            port,
            ptr,
          ),
    );

    final balance = result as String;

    return balance;
  }

  Future<ContractState> get contractState async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_contract_state(
            port,
            ptr,
          ),
    );

    final json = result as Map<String, dynamic>;
    final contractState = ContractState.fromJson(json);

    return contractState;
  }

  @override
  Future<PollingMethod> get pollingMethod => Future.value(PollingMethod.manual);

  Future<InternalMessage> prepareTransfer({
    required String destination,
    required String tokens,
    required bool notifyReceiver,
    String? payload,
  }) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_prepare_transfer(
            port,
            ptr,
            destination.toNativeUtf8().cast<Char>(),
            tokens.toNativeUtf8().cast<Char>(),
            notifyReceiver ? 1 : 0,
            payload?.toNativeUtf8().cast<Char>() ?? nullptr,
          ),
    );

    final json = result as Map<String, dynamic>;
    final internalMessage = InternalMessage.fromJson(json);

    return internalMessage;
  }

  @override
  Future<void> refresh() => executeAsync(
        (port) => NekotonFlutter.instance().bindings.nt_token_wallet_refresh(
              port,
              ptr,
            ),
      );

  Future<void> preloadTransactions(String fromLt) => executeAsync(
        (port) => NekotonFlutter.instance().bindings.nt_token_wallet_preload_transactions(
              port,
              ptr,
              fromLt.toNativeUtf8().cast<Char>(),
            ),
      );

  @override
  Future<void> handleBlock(String block) => executeAsync(
        (port) => NekotonFlutter.instance().bindings.nt_token_wallet_handle_block(
              port,
              ptr,
              block.toNativeUtf8().cast<Char>(),
            ),
      );

  Future<void> dispose() async {
    await _onTransactionsFoundSubscription.cancel();

    _onBalanceChangedPort.close();
    _onTransactionsFoundPort.close();

    await _transactionsSubject.close();
  }

  Future<void> _initialize({
    required String owner,
    required String rootTokenContract,
  }) async {
    onBalanceChangedStream = _onBalanceChangedPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnBalanceChangedPayload.fromJson(json);
      return payload;
    }).asBroadcastStream();

    _onTransactionsFoundStream = _onTransactionsFoundPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnTokenWalletTransactionsFoundPayload.fromJson(json);
      return payload;
    }).asBroadcastStream();

    _onTransactionsFoundSubscription = _onTransactionsFoundStream.listen(
      (event) => _transactionsSubject.tryAdd(
        [
          ..._transactionsSubject.value,
          ...event.transactions,
        ]..sort((a, b) => a.transaction.compareTo(b.transaction)),
      ),
    );

    final transportPtr = _transport.ptr;
    final transportTypeStr = jsonEncode(_transport.type.toString());

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_subscribe(
            port,
            _onBalanceChangedPort.sendPort.nativePort,
            _onTransactionsFoundPort.sendPort.nativePort,
            transportPtr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
            owner.toNativeUtf8().cast<Char>(),
            rootTokenContract.toNativeUtf8().cast<Char>(),
          ),
    );

    _ptr = Pointer.fromAddress(result as int).cast<Void>();

    _nativeFinalizer.attach(this, _ptr);

    _owner = await __owner;
    _address = await __address;
    _symbol = await __symbol;
    _version = await __version;
  }
}
