import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'symbol.freezed.dart';
part 'symbol.g.dart';

@freezed
class Symbol with _$Symbol {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Symbol({
    required String name,
    required String symbol,
    required int decimals,
    required String rootTokenContract,
  }) = _Symbol;

  factory Symbol.fromJson(Map<String, dynamic> json) => _$SymbolFromJson(json);
}
