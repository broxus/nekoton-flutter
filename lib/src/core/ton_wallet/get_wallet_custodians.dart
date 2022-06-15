import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import '../../transport/transport.dart';

Future<List<String>> getWalletCustodians({
  required Transport transport,
  required String address,
}) async {
  final ptr = await transport.clonePtr();
  final transportTypeStr = jsonEncode(transport.type.toString());

  final result = await executeAsync(
    (port) => NekotonFlutter.instance().bindings.nt_get_wallet_custodians(
          port,
          ptr,
          transportTypeStr.toNativeUtf8().cast<Char>(),
          address.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as List<dynamic>;
  final custodians = json.cast<String>();

  return custodians;
}
