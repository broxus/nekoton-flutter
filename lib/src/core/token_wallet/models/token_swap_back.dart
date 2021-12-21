import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'token_swap_back.freezed.dart';
part 'token_swap_back.g.dart';

@freezed
class TokenSwapBack with _$TokenSwapBack {
  @HiveType(typeId: 14)
  const factory TokenSwapBack({
    @HiveField(0) required String tokens,
    @HiveField(1) required String callbackAddress,
    @HiveField(2) required String callbackPayload,
  }) = _TokenSwapBack;

  factory TokenSwapBack.fromJson(Map<String, dynamic> json) => _$TokenSwapBackFromJson(json);
}
