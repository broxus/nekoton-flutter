import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'multisig_type.dart';

part 'wallet_type.freezed.dart';
part 'wallet_type.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.pascal)
class WalletType with _$WalletType {
  @JsonSerializable(fieldRename: FieldRename.snake)
  @HiveType(typeId: 214)
  const factory WalletType.multisig({
    @HiveField(0) required MultisigType multisigType,
  }) = _WalletTypeMultisig;

  @HiveType(typeId: 213)
  const factory WalletType.walletV3() = _WalletTypeWalletV3;

  @HiveType(typeId: 200)
  const factory WalletType.highloadWalletV2() = _WalletTypeHighloadWalletV2;

  factory WalletType.fromJson(Map<String, dynamic> json) => _$WalletTypeFromJson(json);
}
