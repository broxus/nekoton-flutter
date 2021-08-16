import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_recipient.freezed.dart';
part 'transfer_recipient.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class TransferRecipient with _$TransferRecipient {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TransferRecipient.ownerWallet({
    required String address,
  }) = _OwnerWalletRecipient;

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TransferRecipient.tokenWallet({
    required String address,
  }) = _TokenWalletRecipient;

  factory TransferRecipient.fromJson(Map<String, dynamic> json) => _$TransferRecipientFromJson(json);
}
