import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'token_wallet_deployed_notification.freezed.dart';
part 'token_wallet_deployed_notification.g.dart';

@freezed
class TokenWalletDeployedNotification with _$TokenWalletDeployedNotification {
  @HiveType(typeId: 38)
  const factory TokenWalletDeployedNotification({
    @HiveField(0) required String rootTokenContract,
  }) = _TokenWalletDeployedNotification;

  factory TokenWalletDeployedNotification.fromJson(Map<String, dynamic> json) =>
      _$TokenWalletDeployedNotificationFromJson(json);
}
