import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'token_wallet_asset.freezed.dart';
part 'token_wallet_asset.g.dart';

@freezed
class TokenWalletAsset with _$TokenWalletAsset {
  @JsonSerializable(fieldRename: FieldRename.snake)
  @HiveType(typeId: 206)
  const factory TokenWalletAsset({
    @HiveField(0) required String rootTokenContract,
  }) = _TokenWalletAsset;

  factory TokenWalletAsset.fromJson(Map<String, dynamic> json) => _$TokenWalletAssetFromJson(json);
}
