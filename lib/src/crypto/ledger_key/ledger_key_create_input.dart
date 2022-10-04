import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/models/create_key_input.dart';

part 'ledger_key_create_input.freezed.dart';
part 'ledger_key_create_input.g.dart';

@freezed
class LedgerKeyCreateInput with _$LedgerKeyCreateInput implements CreateKeyInput {
  const factory LedgerKeyCreateInput({
    String? name,
    required int accountId,
  }) = _LedgerKeyCreateInput;

  factory LedgerKeyCreateInput.fromJson(Map<String, dynamic> json) =>
      _$LedgerKeyCreateInputFromJson(json);
}
