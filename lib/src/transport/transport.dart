import '../core/models/transaction_id.dart';
import '../external/models/connection_data.dart';

abstract class Transport {
  late final ConnectionData connectionData;

  Future<Map<String, dynamic>> getContractState({
    required String address,
  });

  Future<List<Map<String, dynamic>>> getTransactions({
    required String address,
    required TransactionId from,
    required int count,
  });
}
