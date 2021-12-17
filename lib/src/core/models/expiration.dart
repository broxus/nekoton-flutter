import 'package:freezed_annotation/freezed_annotation.dart';

part 'expiration.freezed.dart';
part 'expiration.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class Expiration with _$Expiration {
  const factory Expiration.never() = _Never;

  const factory Expiration.timeout({
    required int value,
  }) = _Timeout;

  const factory Expiration.timestamp({
    required int value,
  }) = _Timestamp;

  factory Expiration.fromJson(Map<String, dynamic> json) => _$ExpirationFromJson(json);
}
