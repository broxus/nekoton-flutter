import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/depool_asset.dart';
import '../models/token_wallet_asset.dart';

part 'additional_assets.freezed.dart';
part 'additional_assets.g.dart';

@freezed
class AdditionalAssets with _$AdditionalAssets {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory AdditionalAssets({
    required List<TokenWalletAsset> tokenWallets,
    required List<DePoolAsset> depools,
  }) = _AssetsList;

  factory AdditionalAssets.fromJson(Map<String, dynamic> json) => _$AdditionalAssetsFromJson(json);
}
