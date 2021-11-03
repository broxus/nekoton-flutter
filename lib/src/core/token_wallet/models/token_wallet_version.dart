import 'package:freezed_annotation/freezed_annotation.dart';

enum TokenWalletVersion {
  @JsonValue('Tip3v1')
  tip3v1,
  @JsonValue('Tip3v2')
  tip3v2,
  @JsonValue('Tip3v3')
  tip3v3,
  @JsonValue('Tip3v4')
  tip3v4,
}
