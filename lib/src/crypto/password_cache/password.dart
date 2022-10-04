import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/password_cache/password_explicit.dart';

part 'password.freezed.dart';
part 'password.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class Password with _$Password {
  const factory Password.explicit(PasswordExplicit data) = _Explicit;

  const factory Password.fromCache() = _FromCache;

  factory Password.fromJson(Map<String, dynamic> json) => _$PasswordFromJson(json);
}
