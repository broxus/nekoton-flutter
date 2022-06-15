import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_cache_behavior.freezed.dart';
part 'password_cache_behavior.g.dart';

@Freezed(unionKey: 'type')
class PasswordCacheBehavior with _$PasswordCacheBehavior {
  const factory PasswordCacheBehavior.store(int data) = _PasswordCacheBehaviorStore;

  const factory PasswordCacheBehavior.remove() = _PasswordCacheBehaviorRemove;

  const factory PasswordCacheBehavior.nop() = _PasswordCacheBehaviorNop;

  factory PasswordCacheBehavior.fromJson(Map<String, dynamic> json) => _$PasswordCacheBehaviorFromJson(json);
}
