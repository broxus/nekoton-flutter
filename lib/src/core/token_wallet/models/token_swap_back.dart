import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_swap_back.freezed.dart';
part 'token_swap_back.g.dart';

@freezed
class TokenSwapBack with _$TokenSwapBack {
  @JsonSerializable()
  const factory TokenSwapBack({
    required String tokens,
    required String to,
  }) = _TokenSwapBack;

  factory TokenSwapBack.fromJson(Map<String, dynamic> json) => _$TokenSwapBackFromJson(json);
}