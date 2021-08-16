import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/account_subject.dart';
import '../accounts_storage/models/wallet_type.dart';
import '../token_wallet/token_wallet.dart';
import '../ton_wallet/ton_wallet.dart';

part 'account_subscription.freezed.dart';

@freezed
class AccountSubscription with _$AccountSubscription {
  const factory AccountSubscription({
    required AccountSubject accountSubject,
    required TonWallet tonWallet,
    required List<TokenWallet> tokenWallets,
  }) = _AccountSubscription;

  const AccountSubscription._();

  String get publicKey => tonWallet.publicKey;

  String get address => tonWallet.address;

  WalletType get walletType => tonWallet.walletType;
}
