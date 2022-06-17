import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:ffi/ffi.dart';
import 'package:rxdart/rxdart.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import '../../models/pointer_wrapper.dart';
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

final _nativeFinalizer = NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_token_wallet_free_ptr);

void _attach(PointerWrapper pointerWrapper) => _nativeFinalizer.attach(pointerWrapper, pointerWrapper.ptr);

class TokenWallet extends ContractSubscription {
  late final PointerWrapper pointerWrapper;
  final _onBalanceChangedPort = ReceivePort();
  final _onTransactionsFoundPort = ReceivePort();
  late final StreamSubscription _onTransactionsFoundSubscription;
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
        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_token_wallet_owner(
                port,
                pointerWrapper.ptr,
              ),
        );

        final owner = result as String;

        return owner;
      });

  @override
  Future<String> get address => _addressMemo.runOnce(() async {
        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_token_wallet_address(
                port,
                pointerWrapper.ptr,
              ),
        );

        final address = result as String;

        return address;
      });

  Future<Symbol> get symbol => _symbolMemo.runOnce(() async {
        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_token_wallet_symbol(
                port,
                pointerWrapper.ptr,
              ),
        );

        final json = result as Map<String, dynamic>;
        final symbol = Symbol.fromJson(json);

        return symbol;
      });

  Future<TokenWalletVersion> get version => _versionMemo.runOnce(() async {
        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_token_wallet_version(
                port,
                pointerWrapper.ptr,
              ),
        );

        final json = result as String;
        final version = TokenWalletVersion.values.firstWhere((e) => e.toString() == json);

        return version;
      });

  Future<String> get balance async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_balance(
            port,
            pointerWrapper.ptr,
          ),
    );

    final balance = result as String;

    return balance;
  }

  Future<ContractState> get contractState async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_contract_state(
            port,
            pointerWrapper.ptr,
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
            pointerWrapper.ptr,
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
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_refresh(
            port,
            pointerWrapper.ptr,
          ),
    );
  }

  Future<void> preloadTransactions(TransactionId from) async {
    final fromStr = jsonEncode(from);

    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_preload_transactions(
            port,
            pointerWrapper.ptr,
            fromStr.toNativeUtf8().cast<Char>(),
          ),
    );
  }

  @override
  Future<void> handleBlock(String block) async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_token_wallet_handle_block(
            port,
            pointerWrapper.ptr,
            block.toNativeUtf8().cast<Char>(),
          ),
    );
  }

  Future<void> dispose() async {
    await _onTransactionsFoundSubscription.cancel();

    _onBalanceChangedPort.close();
    _onTransactionsFoundPort.close();

    await _transactionsSubject.close();

    await pausePolling();
  }

  Future<void> _initialize({
    required Transport transport,
    required String owner,
    required String rootTokenContract,
  }) async {
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

    _onTransactionsFoundSubscription = _onTransactionsFoundPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = OnTokenWalletTransactionsFoundPayload.fromJson(json);
      return payload;
    }).listen(
      (event) {
        if (!_transactionsSubject.isClosed) {
          _transactionsSubject.add(
            [
              ..._transactionsSubject.value,
              ...event.transactions,
            ]..sort((a, b) => a.transaction.compareTo(b.transaction)),
          );
        }
      },
    );

    final transportPtr = transport.pointerWrapper.ptr;
    final transportTypeStr = jsonEncode(transport.type.toString());

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

    pointerWrapper = PointerWrapper(Pointer.fromAddress(result as int).cast<Void>());

    _attach(pointerWrapper);

    await startPolling();
  }
}
