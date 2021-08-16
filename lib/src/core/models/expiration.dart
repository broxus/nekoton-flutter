import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'expiration.freezed.dart';
part 'expiration.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class Expiration with _$Expiration {
  @JsonSerializable()
  const factory Expiration.never() = _Never;

  @JsonSerializable()
  const factory Expiration.timeout({
    required int value,
  }) = _Timeout;

  @JsonSerializable()
  const factory Expiration.timestamp({
    required int value,
  }) = _Timestamp;

  factory Expiration.fromJson(Map<String, dynamic> json) => _$ExpirationFromJson(json);
}
