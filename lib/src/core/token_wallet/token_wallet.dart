import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/models/contract_state.dart';
import 'package:nekoton_flutter/src/core/models/internal_message.dart';
import 'package:nekoton_flutter/src/core/models/transaction_with_data.dart';
import 'package:nekoton_flutter/src/core/models/transactions_batch_info.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/symbol.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/token_wallet_transaction.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/token_wallet_version.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';
import 'package:tuple/tuple.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_token_wallet_free_ptr);

class TokenWallet implements Finalizable {
  late final Pointer<Void> _ptr;
  final Transport _transport;
  final _onBalanceChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  late final Stream<String> onBalanceChangedStream;
  late final Stream<
          Tuple2<List<TransactionWithData<TokenWalletTransaction?>>, TransactionsBatchInfo>>
      onTransactionsFoundStream;
  late final String _owner;
  late final String _address;
  late final Symbol _symbol;
  late final TokenWalletVersion _version;
  late String _balance;
  late ContractState _contractState;

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

  Transport get transport => _transport;

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

  String get balance => _balance;

  Future<String> get __balance async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_balance(
            port,
            ptr,
          ),
    );

    final balance = result as String;

    return balance;
  }

  ContractState get contractState => _contractState;

  Future<ContractState> get __contractState async {
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

  Future<void> refresh() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_refresh(
            port,
            ptr,
          ),
    );

    await _updateData();
  }

  Future<void> preloadTransactions(String fromLt) async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_preload_transactions(
            port,
            ptr,
            fromLt.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();
  }

  Future<void> handleBlock(String block) async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_handle_block(
            port,
            ptr,
            block.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();
  }

  Future<void> dispose() async {
    _onBalanceChangedPort.close();
    _onTransactionsFoundPort.close();
  }

  Future<void> _updateData() async {
    _balance = await __balance;
    _contractState = await __contractState;
  }

  Future<void> _initialize({
    required String owner,
    required String rootTokenContract,
  }) async {
    onBalanceChangedStream = _onBalanceChangedPort
        .cast<String>()
        .asBroadcastStream(onCancel: (subscription) => subscription.cancel());

    onTransactionsFoundStream = _onTransactionsFoundPort.cast<String>().map((e) {
      final json = jsonDecode(e) as List<dynamic>;

      final transactionsJson = json.first as List<dynamic>;
      final transactions = transactionsJson
          .cast<Map<String, dynamic>>()
          .map(
            (e) => TransactionWithData<TokenWalletTransaction?>.fromJson(
              e,
              (json) => json != null
                  ? TokenWalletTransaction.fromJson(json as Map<String, dynamic>)
                  : null,
            ),
          )
          .toList();
      final batchInfoJson = json.last as Map<String, dynamic>;
      final batchInfo = TransactionsBatchInfo.fromJson(batchInfoJson);

      return Tuple2(transactions, batchInfo);
    }).asBroadcastStream(onCancel: (subscription) => subscription.cancel());

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

    _ptr = toPtrFromAddress(result as String);

    _nativeFinalizer.attach(this, _ptr);

    _owner = await __owner;
    _address = await __address;
    _symbol = await __symbol;
    _version = await __version;

    await _updateData();
  }
}
