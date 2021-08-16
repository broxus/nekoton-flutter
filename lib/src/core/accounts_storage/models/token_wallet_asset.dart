import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_wallet_asset.freezed.dart';
part 'token_wallet_asset.g.dart';

@freezed
class TokenWalletAsset with _$TokenWalletAsset {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TokenWalletAsset({
    required String rootTokenContract,
  }) = _TokenWalletAsset;

  factory TokenWalletAsset.fromJson(Map<String, dynamic> json) => _$TokenWalletAssetFromJson(json);
}
