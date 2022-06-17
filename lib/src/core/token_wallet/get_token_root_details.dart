import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import '../../transport/transport.dart';
import 'models/root_token_contract_details.dart';

Future<RootTokenContractDetails> getTokenRootDetails({
  required Transport transport,
  required String rootTokenContract,
}) async {
  final ptr = transport.pointerWrapper.ptr;
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
