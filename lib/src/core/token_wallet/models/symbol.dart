import 'package:freezed_annotation/freezed_annotation.dart';

part 'symbol.freezed.dart';
part 'symbol.g.dart';

@freezed
class Symbol with _$Symbol {
  const factory Symbol({
    required String name,
    required String fullName,
    required int decimals,
    required String rootTokenContract,
  }) = _Symbol;

  factory Symbol.fromJson(Map<String, dynamic> json) => _$SymbolFromJson(json);
}
