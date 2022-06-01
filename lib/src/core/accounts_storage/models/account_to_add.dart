import 'package:freezed_annotation/freezed_annotation.dart';

import 'wallet_type.dart';

part 'account_to_add.freezed.dart';
part 'account_to_add.g.dart';

@freezed
class AccountToAdd with _$AccountToAdd {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory AccountToAdd({
    required String name,
    required String publicKey,
    required WalletType contract,
    required int workchain,
    String? explicitAddress,
  }) = _AccountToAdd;

  factory AccountToAdd.fromJson(Map<String, dynamic> json) => _$AccountToAddFromJson(json);
}