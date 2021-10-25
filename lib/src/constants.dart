import 'core/accounts_storage/models/multisig_type.dart';
import 'core/accounts_storage/models/wallet_type.dart';
import 'core/models/expiration.dart';

const kDefaultWorkchain = 0;

const kTonDecimals = 9;

const kProviderVersion = "0.2.13";

const kGqlRefreshPeriod = Duration(seconds: 15);

const kRequestTimeout = Duration(seconds: 30);

const kDefaultMessageExpiration = Expiration.timeout(value: 30);

const kAvailableWallets = [
  WalletType.multisig(multisigType: MultisigType.safeMultisigWallet),
  WalletType.multisig(multisigType: MultisigType.safeMultisigWallet24h),
  WalletType.multisig(multisigType: MultisigType.setcodeMultisigWallet),
  WalletType.multisig(multisigType: MultisigType.bridgeMultisigWallet),
  WalletType.multisig(multisigType: MultisigType.surfWallet),
  WalletType.walletV3(),
];
