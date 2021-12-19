import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'wallet_type.dart';

part 'ton_wallet_asset.freezed.dart';
part 'ton_wallet_asset.g.dart';

@freezed
class TonWalletAsset with _$TonWalletAsset {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  @HiveType(typeId: 208)
  const factory TonWalletAsset({
    @HiveField(0) required String address,
    @HiveField(1) required String publicKey,
    @HiveField(2) required WalletType contract,
  }) = _TonWalletAsset;

  factory TonWalletAsset.fromJson(Map<String, dynamic> json) => _$TonWalletAssetFromJson(json);

  const TonWalletAsset._();

  int get workchain => int.parse(address.split(':').first);
}
