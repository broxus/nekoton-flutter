import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/root_token_contract_details.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';
import 'package:tuple/tuple.dart';

Future<Tuple2<String, RootTokenContractDetails>> getTokenRootDetailsFromTokenWallet({
  required Transport transport,
  required String tokenWalletAddress,
}) async {
  final ptr = transport.ptr;
  final transportTypeStr = jsonEncode(transport.type.toString());

  final result = await executeAsync(
    (port) => NekotonFlutter.instance().bindings.nt_get_token_wallet_details(
          port,
          ptr,
          transportTypeStr.toNativeUtf8().cast<Char>(),
          tokenWalletAddress.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as List<dynamic>;
  final rootTokenContract = json.first as String;
  final rootContractDetails = RootTokenContractDetails.fromJson(json.last as Map<String, dynamic>);

  return Tuple2(rootTokenContract, rootContractDetails);
}
