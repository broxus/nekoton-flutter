import 'package:freezed_annotation/freezed_annotation.dart';

enum TransactionsBatchType {
  @JsonValue('old')
  oldTransactions,
  @JsonValue('new')
  newTransactions,
}
