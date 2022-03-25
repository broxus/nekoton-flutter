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
  final ptr = await transport.clonePtr();
  final transportType = transport.connectionData.type;

  final result = await executeAsync(
    (port) => NekotonFlutter.bindings.get_token_root_details(
      port,
      ptr,
      transportType.index,
      rootTokenContract.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final tokenRootDetails = RootTokenContractDetails.fromJson(json);

  return tokenRootDetails;
}
