import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../nekoton_flutter.dart';
import '../../bindings.dart';
import '../../ffi_utils.dart';

Future<List<String>> getWalletCustodians({
  required Transport transport,
  required String address,
}) async {
  final ptr = await transport.clonePtr();
  final transportType = transport.connectionData.type;

  final result = await executeAsync(
    (port) => bindings().get_wallet_custodians(
      port,
      ptr,
      transportType.index,
      address.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as List<dynamic>;
  final custodians = json.cast<String>();

  return custodians;
}
