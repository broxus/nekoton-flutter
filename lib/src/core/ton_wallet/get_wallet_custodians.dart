import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';

Future<List<String>> getWalletCustodians({
  required Transport transport,
  required String address,
}) async {
  final ptr = transport.ptr;
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
