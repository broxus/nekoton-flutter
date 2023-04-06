import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/models/accounts_list.dart';
import 'package:nekoton_flutter/src/core/models/full_contract_state.dart';
import 'package:nekoton_flutter/src/core/models/raw_contract_state.dart';
import 'package:nekoton_flutter/src/core/models/transaction.dart';
import 'package:nekoton_flutter/src/core/models/transactions_list.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/models/transport_type.dart';

abstract class Transport {
  Pointer<Void> get ptr;

  String get name;

  int get networkId;

  String get group;

  TransportType get type;

  Future<RawContractState> getContractState(String address) async {
    final transportTypeStr = jsonEncode(type.toString());

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_transport_get_contract_state(
            port,
            ptr,
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
            ptr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
            address.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>?;
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
            ptr,
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
    String? fromLt,
    required int limit,
  }) async {
    final transportTypeStr = jsonEncode(type.toString());

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_transport_get_transactions(
            port,
            ptr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
            address.toNativeUtf8().cast<Char>(),
            fromLt?.toNativeUtf8().cast<Char>() ?? nullptr,
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
            ptr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
            hash.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>?;
    final transaction = json != null ? Transaction.fromJson(json) : null;

    return transaction;
  }

  Future<String?> getSignatureId() async {
    final transportTypeStr = jsonEncode(type.toString());

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_transport_get_signature_id(
            port,
            ptr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
          ),
    );
    final value = result as String?;
    return value;
  }

  Future<int> getNetworkId() async {
    final transportTypeStr = jsonEncode(type.toString());

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_transport_get_network_id(
            port,
            ptr,
            transportTypeStr.toNativeUtf8().cast<Char>(),
          ),
    );
    final value = result as int;
    return value;
  }

  Future<void> dispose();
}
