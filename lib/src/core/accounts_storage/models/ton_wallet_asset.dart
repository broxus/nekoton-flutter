import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'wallet_type.dart';

part 'ton_wallet_asset.freezed.dart';
part 'ton_wallet_asset.g.dart';

@freezed
class TonWalletAsset with _$TonWalletAsset {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory TonWalletAsset({
    required String address,
    required String publicKey,
    required WalletType contract,
  }) = _TonWalletAsset;

  factory TonWalletAsset.fromJson(Map<String, dynamic> json) => _$TonWalletAssetFromJson(json);
}
