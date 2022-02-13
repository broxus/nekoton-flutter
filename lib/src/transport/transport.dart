import 'dart:async';
import 'dart:ffi';

import '../core/models/transaction_id.dart';
import '../models/pointed.dart';
import '../utils/models/full_contract_state.dart';
import '../utils/models/transactions_list.dart';
import 'models/connection_data.dart';

abstract class Transport implements Pointed {
  late final ConnectionData connectionData;

  Future<FullContractState?> getFullAccountState({
    required String address,
  });

  Future<TransactionsList> getTransactions({
    required String address,
    TransactionId? continuation,
    int? limit,
  });

  @override
  Future<Pointer<Void>> clonePtr();

  @override
  Future<void> freePtr();
}
