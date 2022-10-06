import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:tuple/tuple.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import '../../transport/transport.dart';
import 'models/root_token_contract_details.dart';
import 'models/token_wallet_details.dart';

Future<Tuple2<TokenWalletDetails, RootTokenContractDetails>> getTokenWalletDetails({
  required Transport transport,
  required String tokenWallet,
}) async {
  final ptr = await transport.clonePtr();
  final transportType = transport.connectionData.type;

  final result = await executeAsync(
    (port) => NekotonFlutter.instance().bindings.nt_get_token_wallet_details(
          port,
          ptr,
          transportType.index,
          tokenWallet.toNativeUtf8().cast<Char>(),
        ),
  );

  final list = result as List<Map<String, dynamic>>;
  final tokenWalletDetails = TokenWalletDetails.fromJson(list.first);
  final rootContractDetails = RootTokenContractDetails.fromJson(list.last);

  return Tuple2(tokenWalletDetails, rootContractDetails);
}
