import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'symbol.freezed.dart';
part 'symbol.g.dart';

@freezed
class Symbol with _$Symbol {
  @HiveType(typeId: 219)
  const factory Symbol({
    @HiveField(0) required String name,
    @HiveField(1) required String fullName,
    @HiveField(2) required int decimals,
    @HiveField(3) required String rootTokenContract,
  }) = _Symbol;

  factory Symbol.fromJson(Map<String, dynamic> json) => _$SymbolFromJson(json);
}
