import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_wallet_deployed_notification.freezed.dart';
part 'token_wallet_deployed_notification.g.dart';

@freezed
class TokenWalletDeployedNotification with _$TokenWalletDeployedNotification {
  const factory TokenWalletDeployedNotification({
    required String rootTokenContract,
  }) = _TokenWalletDeployedNotification;

  factory TokenWalletDeployedNotification.fromJson(Map<String, dynamic> json) =>
      _$TokenWalletDeployedNotificationFromJson(json);
}
