import '../core/models/transaction_id.dart';

abstract class Transport {
  Future<Map<String, dynamic>> getContractState({
    required String address,
  });

  Future<List<Map<String, dynamic>>> getTransactions({
    required String address,
    required TransactionId from,
    required int count,
  });
}
