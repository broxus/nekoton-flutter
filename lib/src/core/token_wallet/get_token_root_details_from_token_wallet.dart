import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:tuple/tuple.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import '../../transport/transport.dart';
import 'models/root_token_contract_details.dart';

Future<Tuple2<String, RootTokenContractDetails>> getTokenRootDetailsFromTokenWallet({
  required Transport transport,
  required String tokenWalletAddress,
}) async {
  final ptr = await transport.clonePtr();
  final transportType = transport.connectionData.type;

  final result = await executeAsync(
    (port) => NekotonFlutter.bindings.nt_get_token_wallet_details(
      port,
      ptr,
      transportType.index,
      tokenWalletAddress.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = cStringToDart(result);
  final list = jsonDecode(string) as List<dynamic>;
  final rootTokenContract = list.first as String;
  final rootContractDetails = RootTokenContractDetails.fromJson(list.last as Map<String, dynamic>);

  return Tuple2(rootTokenContract, rootContractDetails);
}
