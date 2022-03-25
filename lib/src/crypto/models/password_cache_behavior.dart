import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_cache_behavior.freezed.dart';
part 'password_cache_behavior.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class PasswordCacheBehavior with _$PasswordCacheBehavior {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
  )
  const factory PasswordCacheBehavior.store({
    required int duration,
  }) = _PasswordCacheBehaviorStore;

  const factory PasswordCacheBehavior.remove() = _PasswordCacheBehaviorRemove;

  factory PasswordCacheBehavior.fromJson(Map<String, dynamic> json) => _$PasswordCacheBehaviorFromJson(json);
}
