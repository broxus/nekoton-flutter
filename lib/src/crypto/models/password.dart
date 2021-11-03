import 'package:freezed_annotation/freezed_annotation.dart';

import 'password_cache_behavior.dart';

part 'password.freezed.dart';
part 'password.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class Password with _$Password {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory Password.explicit({
    required String password,
    required PasswordCacheBehavior cacheBehavior,
  }) = _Explicit;

  const factory Password.fromCache() = _FromCache;

  factory Password.fromJson(Map<String, dynamic> json) => _$PasswordFromJson(json);
}
