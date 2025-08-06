import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/models/transaction.dart';

part 'transaction_with_data.freezed.dart';
part 'transaction_with_data.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class TransactionWithData<T>
    with _$TransactionWithData<T>
    implements Comparable<TransactionWithData<T>> {
  const factory TransactionWithData({
    required Transaction transaction,
    T? data,
  }) = _TransactionWithData<T>;

  const TransactionWithData._();

  factory TransactionWithData.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$TransactionWithDataFromJson<T>(json, fromJsonT);

  @override
  int compareTo(TransactionWithData other) =>
      transaction.compareTo(other.transaction);
}
