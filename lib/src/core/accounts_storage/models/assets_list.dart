import 'package:freezed_annotation/freezed_annotation.dart';

import 'additional_assets.dart';
import 'ton_wallet_asset.dart';

part 'assets_list.freezed.dart';
part 'assets_list.g.dart';

@freezed
class AssetsList with _$AssetsList implements Comparable<AssetsList> {
  const factory AssetsList({
    required String name,
    required TonWalletAsset tonWallet,
    required Map<String, AdditionalAssets> additionalAssets,
  }) = _AssetsList;

  factory AssetsList.fromJson(Map<String, dynamic> json) => _$AssetsListFromJson(json);

  const AssetsList._();

  String get publicKey => tonWallet.publicKey;

  String get address => tonWallet.address;

  int get workchain => tonWallet.workchain;

  @override
  int compareTo(AssetsList other) => address.compareTo(other.address);
}
