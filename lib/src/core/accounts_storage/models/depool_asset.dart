import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'depool_asset.freezed.dart';
part 'depool_asset.g.dart';

@freezed
class DePoolAsset with _$DePoolAsset {
  @HiveType(typeId: 205)
  const factory DePoolAsset({
    @HiveField(0) required String address,
  }) = _DePoolAsset;

  factory DePoolAsset.fromJson(Map<String, dynamic> json) => _$DePoolAssetFromJson(json);
}
