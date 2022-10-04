import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_recipient.freezed.dart';
part 'transfer_recipient.g.dart';

@Freezed(unionKey: 'type')
class TransferRecipient with _$TransferRecipient {
  const factory TransferRecipient.ownerWallet(String data) = _OwnerWallet;

  const factory TransferRecipient.tokenWallet(String data) = _TokenWallet;

  factory TransferRecipient.fromJson(Map<String, dynamic> json) =>
      _$TransferRecipientFromJson(json);
}
