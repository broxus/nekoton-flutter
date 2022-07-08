import 'package:freezed_annotation/freezed_annotation.dart';

part 'ledger_signature_context.freezed.dart';
part 'ledger_signature_context.g.dart';

@freezed
class LedgerSignatureContext with _$LedgerSignatureContext {
  const factory LedgerSignatureContext({
    required int decimals,
    required String asset,
    required String amount,
    required String address,
  }) = _LedgerSignatureContext;

  factory LedgerSignatureContext.fromJson(Map<String, dynamic> json) =>
      _$LedgerSignatureContextFromJson(json);
}
