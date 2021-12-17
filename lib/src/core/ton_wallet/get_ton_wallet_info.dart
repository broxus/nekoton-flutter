import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../ffi_utils.dart';
import '../../nekoton.dart';
import '../../transport/gql_transport.dart';
import 'models/ton_wallet_info.dart';

Future<TonWalletInfo> getTonWalletInfo({
  required GqlTransport transport,
  required String address,
}) async {
  final result = await transport.nativeGqlTransport.use(
    (ptr) => proceedAsync(
      (port) => nativeLibraryInstance.bindings.get_ton_wallet_info(
        port,
        ptr,
        address.toNativeUtf8().cast<Int8>(),
      ),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final info = TonWalletInfo.fromJson(json);

  return info;
}
