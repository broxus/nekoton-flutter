import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:ffi/ffi.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import '../../models/pointed.dart';
import '../../transport/transport.dart';
import '../contract_subscription/contract_subscription.dart';
import '../models/contract_state.dart';
import '../models/internal_message.dart';
import '../models/polling_method.dart';
import '../models/transaction_id.dart';
import 'models/on_balance_changed_payload.dart';
import 'models/on_token_wallet_transactions_found_payload.dart';
import 'models/symbol.dart';
import 'models/token_wallet_transaction_with_data.dart';
import 'models/token_wallet_version.dart';

class TokenWallet extends ContractSubscription implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;
  final _onBalanceChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  final _transactionsSubject = BehaviorSubject<List<TokenWalletTransactionWithData>>.seeded([]);
  late final Stream<String> balanceChangesStream;
  late final Stream<List<TokenWalletTransactionWithData>> transactionsStream = _transactionsSubject;
  @override
  late final Transport transport;
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
          (port) => NekotonFlutter.instance().bindings.nt_token_wallet_owner(
                port,
                ptr,
              ),
        );

        final owner = result as String;

        return owner;
      });

  @override
  Future<String> get address => _addressMemo.runOnce(() async {
        final ptr = await clonePtr();

        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_token_wallet_address(
                port,
                ptr,
              ),
        );

        final address = result as String;

        return address;
      });

  Future<Symbol> get symbol => _symbolMemo.runOnce(() async {
        final ptr = await clonePtr();

        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_token_wallet_symbol(
                port,
                ptr,
              ),
        );

        final json = result as Map<String, dynamic>;
        final symbol = Symbol.fromJson(json);

        return symbol;
      });

  Future<TokenWalletVersion> get version => _versionMemo.runOnce(() async {
        final ptr = await clonePtr();

        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_token_wallet_version(
                port,
                ptr,
              ),
        );

        final json = result as String;
        final version = tokenWalletVersionFromEnumString(json);

        return version;
      });

  Future<String> get balance async {
    final ptr = await clonePtr();

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
    final ptr = await clonePtr();

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
    final ptr = await clonePtr();

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
  Future<void> refresh() async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_refresh(
            port,
            ptr,
          ),
    );
  }

  Future<void> preloadTransactions(TransactionId from) async {
    final ptr = await clonePtr();
    final fromStr = jsonEncode(from);

    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_preload_transactions(
            port,
            ptr,
            fromStr.toNativeUtf8().cast<Char>(),
          ),
    );
  }

  @override
  Future<void> handleBlock(String block) async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_handle_block(
            port,
            ptr,
            block.toNativeUtf8().cast<Char>(),
          ),
    );
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Token wallet use after free');

        final ptr = NekotonFlutter.instance().bindings.nt_token_wallet_clone_ptr(
              _ptr!,
            );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() async {
        if (_ptr == null) return;

        _onBalanceChangedPort.close();
        _onTransactionsFoundPort.close();

        _transactionsSubject.close();

        await pausePolling();

        NekotonFlutter.instance().bindings.nt_token_wallet_free_ptr(
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
          (port) => NekotonFlutter.instance().bindings.nt_token_wallet_subscribe(
                port,
                _onBalanceChangedPort.sendPort.nativePort,
                _onTransactionsFoundPort.sendPort.nativePort,
                transportPtr,
                transportType.index,
                owner.toNativeUtf8().cast<Char>(),
                rootTokenContract.toNativeUtf8().cast<Char>(),
              ),
        );

        _ptr = toPtrFromAddress(result as String);

        await startPolling();
      });
}
