import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  @HiveType(typeId: 207)
  const factory AdditionalAssets({
    @HiveField(0) required List<TokenWalletAsset> tokenWallets,
    @HiveField(1) required List<DePoolAsset> depools,
  }) = _AdditionalAssets;

  factory AdditionalAssets.fromJson(Map<String, dynamic> json) => _$AdditionalAssetsFromJson(json);
}
