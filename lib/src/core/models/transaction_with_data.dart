import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/models/transaction.dart';

part 'transaction_with_data.freezed.dart';
part 'transaction_with_data.g.dart';

@freezed
@JsonSerializable(genericArgumentFactories: true)
class TransactionWithData<T>
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
  ) {
    return _$TransactionWithDataFromJson<T>(json, fromJsonT);
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return _$TransactionWithDataToJson<T>(this, toJsonT);
  }

  @override
  int compareTo(TransactionWithData other) => transaction.compareTo(other.transaction);
}
