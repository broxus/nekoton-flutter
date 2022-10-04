import 'package:freezed_annotation/freezed_annotation.dart';

part 'expiration.freezed.dart';
part 'expiration.g.dart';

@Freezed(unionKey: 'type')
class Expiration with _$Expiration {
  const factory Expiration.never() = _Never;

  const factory Expiration.timeout(int data) = _Timeout;

  const factory Expiration.timestamp(int data) = _Timestamp;

  factory Expiration.fromJson(Map<String, dynamic> json) => _$ExpirationFromJson(json);
}
