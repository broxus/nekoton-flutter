import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/accounts_storage/models/wallet_type.dart';

part 'ton_wallet_asset.freezed.dart';
part 'ton_wallet_asset.g.dart';

@freezed
class TonWalletAsset with _$TonWalletAsset {
  const factory TonWalletAsset({
    required String address,
    required String publicKey,
    required WalletType contract,
  }) = _TonWalletAsset;

  factory TonWalletAsset.fromJson(Map<String, dynamic> json) => _$TonWalletAssetFromJson(json);

  const TonWalletAsset._();

  int get workchain => int.parse(address.split(':').first);
}
