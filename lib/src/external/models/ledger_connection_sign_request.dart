import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/external/models/ledger_signature_context.dart';

part 'ledger_connection_sign_request.freezed.dart';
part 'ledger_connection_sign_request.g.dart';

@freezed
class LedgerConnectionSignRequest with _$LedgerConnectionSignRequest {
  const factory LedgerConnectionSignRequest({
    required String tx,
    required int account,
    required List<int> message,
    LedgerSignatureContext? context,
  }) = _LedgerConnectionSignRequest;

  factory LedgerConnectionSignRequest.fromJson(Map<String, dynamic> json) =>
      _$LedgerConnectionSignRequestFromJson(json);
}
