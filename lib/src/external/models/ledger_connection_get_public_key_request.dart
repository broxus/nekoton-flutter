import 'package:freezed_annotation/freezed_annotation.dart';

part 'ledger_connection_get_public_key_request.freezed.dart';
part 'ledger_connection_get_public_key_request.g.dart';

@freezed
class LedgerConnectionGetPublicKeyRequest with _$LedgerConnectionGetPublicKeyRequest {
  const factory LedgerConnectionGetPublicKeyRequest({
    required int tx,
    required int accountId,
  }) = _LedgerConnectionGetPublicKeyRequest;

  factory LedgerConnectionGetPublicKeyRequest.fromJson(Map<String, dynamic> json) =>
      _$LedgerConnectionGetPublicKeyRequestFromJson(json);
}
