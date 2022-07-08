import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/token_wallet/models/root_token_contract_details.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';

Future<RootTokenContractDetails> getTokenRootDetails({
  required Transport transport,
  required String rootTokenContract,
}) async {
  final ptr = transport.ptr;
  final transportTypeStr = jsonEncode(transport.type.toString());

  final result = await executeAsync(
    (port) => NekotonFlutter.instance().bindings.nt_get_token_root_details(
          port,
          ptr,
          transportTypeStr.toNativeUtf8().cast<Char>(),
          rootTokenContract.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as Map<String, dynamic>;
  final tokenRootDetails = RootTokenContractDetails.fromJson(json);

  return tokenRootDetails;
}
