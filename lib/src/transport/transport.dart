import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../core/models/accounts_list.dart';
import '../core/models/full_contract_state.dart';
import '../core/models/raw_contract_state.dart';
import '../core/models/transaction.dart';
import '../core/models/transaction_id.dart';
import '../core/models/transactions_list.dart';
import '../ffi_utils.dart';
import '../models/pointer_wrapper.dart';
import 'models/transport_type.dart';

abstract class Transport {
  abstract final PointerWrapper pointerWrapper;

  TransportType get type;

  String get group;

  Future<RawContractState> getContractState(String address) async {
    final transportTypeStr = jsonEncode(type.toString());

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_transport_get_contract_state(
            port,
            pointerWrapper.ptr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
            address.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;
    final contractState = RawContractState.fromJson(json);

    return contractState;
  }

  Future<FullContractState?> getFullContractState(String address) async {
    final transportTypeStr = jsonEncode(type.toString());

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_transport_get_full_contract_state(
            port,
            pointerWrapper.ptr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
            address.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result != null ? result as Map<String, dynamic> : null;
    final fullContractState = json != null ? FullContractState.fromJson(json) : null;

    return fullContractState;
  }

  Future<AccountsList> getAccountsByCodeHash({
    required String codeHash,
    required int limit,
    String? continuation,
  }) async {
    final transportTypeStr = jsonEncode(type.toString());

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_transport_get_accounts_by_code_hash(
            port,
            pointerWrapper.ptr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
            codeHash.toNativeUtf8().cast<Char>(),
            limit,
            continuation?.toNativeUtf8().cast<Char>() ?? nullptr,
          ),
    );

    final json = result as Map<String, dynamic>;
    final accountsList = AccountsList.fromJson(json);

    return accountsList;
  }

  Future<TransactionsList> getTransactions({
    required String address,
    TransactionId? continuation,
    required int limit,
  }) async {
    final transportTypeStr = jsonEncode(type.toString());
    final continuationStr = continuation != null ? jsonEncode(continuation) : null;

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_transport_get_transactions(
            port,
            pointerWrapper.ptr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
            address.toNativeUtf8().cast<Char>(),
            continuationStr?.toNativeUtf8().cast<Char>() ?? nullptr,
            limit,
          ),
    );

    final json = result as Map<String, dynamic>;
    final transactionsList = TransactionsList.fromJson(json);

    return transactionsList;
  }

  Future<Transaction?> getTransaction(String hash) async {
    final transportTypeStr = jsonEncode(type.toString());

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_transport_get_transaction(
            port,
            pointerWrapper.ptr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
            hash.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result != null ? result as Map<String, dynamic> : null;
    final transaction = json != null ? Transaction.fromJson(json) : null;

    return transaction;
  }
}
