import 'package:freezed_annotation/freezed_annotation.dart';

import 'password_explicit.dart';

part 'password.freezed.dart';
part 'password.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class Password with _$Password {
  const factory Password.explicit(PasswordExplicit data) = _PasswordExplicit;

  const factory Password.fromCache() = _PasswordFromCache;

  factory Password.fromJson(Map<String, dynamic> json) => _$PasswordFromJson(json);
}
