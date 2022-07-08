import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/crypto/models/sign_input.dart';
import 'package:nekoton_flutter/src/external/models/ledger_signature_context.dart';

part 'ledger_sign_input.freezed.dart';
part 'ledger_sign_input.g.dart';

@freezed
class LedgerSignInput with _$LedgerSignInput implements SignInput {
  const factory LedgerSignInput({
    required String publicKey,
    LedgerSignatureContext? context,
  }) = _LedgerSignInput;

  factory LedgerSignInput.fromJson(Map<String, dynamic> json) => _$LedgerSignInputFromJson(json);
}
