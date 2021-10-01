import '../core/models/transaction_id.dart';
import '../external/models/connection_data.dart';
import '../provider/models/full_contract_state.dart';
import '../provider/models/transactions_list.dart';

abstract class Transport {
  late final ConnectionData connectionData;

  Future<FullContractState?> getFullAccountState({
    required String address,
  });

  Future<TransactionsList> getTransactions({
    required String address,
    TransactionId? continuation,
    int? limit,
  });
}
