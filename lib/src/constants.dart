import 'core/accounts_storage/models/multisig_type.dart';
import 'core/accounts_storage/models/wallet_type.dart';
import 'core/models/expiration.dart';
import 'external/models/connection_data.dart';

const kDefaultWorkchain = 0;

const kTonDecimals = 9;

const kProviderVersion = '0.2.13';

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

const kNetworkPresets = <ConnectionData>[
  ConnectionData(
    name: 'Mainnet (GQL 1)',
    group: 'mainnet',
    type: 'graphql',
    endpoint: 'https://main.ton.dev/',
    timeout: 60000,
  ),
  ConnectionData(
    name: 'Mainnet (GQL 2)',
    group: 'mainnet',
    type: 'graphql',
    endpoint: 'https://main2.ton.dev/',
    timeout: 60000,
  ),
  ConnectionData(
    name: 'Mainnet (GQL 3)',
    group: 'mainnet',
    type: 'graphql',
    endpoint: 'https://main3.ton.dev/',
    timeout: 60000,
  ),
  ConnectionData(
    name: 'Testnet',
    group: 'testnet',
    type: 'graphql',
    endpoint: 'https://net.ton.dev/',
    timeout: 60000,
  ),
  ConnectionData(
    name: 'fld.ton.dev',
    group: 'fld',
    type: 'graphql',
    endpoint: 'https://gql.custler.net/',
    timeout: 60000,
  ),
];
