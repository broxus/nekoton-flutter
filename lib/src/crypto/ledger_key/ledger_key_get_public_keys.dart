import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/models/get_public_keys.dart';

part 'ledger_key_get_public_keys.freezed.dart';
part 'ledger_key_get_public_keys.g.dart';

@freezed
class LedgerKeyGetPublicKeys with _$LedgerKeyGetPublicKeys implements GetPublicKeys {
  const factory LedgerKeyGetPublicKeys({
    required int offset,
    required int limit,
  }) = _LedgerKeyGetPublicKeysRename;

  factory LedgerKeyGetPublicKeys.fromJson(Map<String, dynamic> json) =>
      _$LedgerKeyGetPublicKeysFromJson(json);
}
