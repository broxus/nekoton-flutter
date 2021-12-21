import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'transfer_recipient.freezed.dart';
part 'transfer_recipient.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class TransferRecipient with _$TransferRecipient {
  @JsonSerializable(fieldRename: FieldRename.snake)
  @HiveType(typeId: 24)
  const factory TransferRecipient.ownerWallet({
    @HiveField(0) required String address,
  }) = _OwnerWalletRecipient;

  @JsonSerializable(fieldRename: FieldRename.snake)
  @HiveType(typeId: 25)
  const factory TransferRecipient.tokenWallet({
    @HiveField(0) required String address,
  }) = _TokenWalletRecipient;

  factory TransferRecipient.fromJson(Map<String, dynamic> json) => _$TransferRecipientFromJson(json);
}
