import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../ffi_utils.dart';
import '../../nekoton.dart';
import '../../transport/gql_transport.dart';
import 'models/token_wallet_info.dart';

Future<TokenWalletInfo> getTokenWalletInfo({
  required GqlTransport transport,
  required String owner,
  required String rootTokenContract,
}) async {
  final result = await transport.nativeGqlTransport.use(
    (ptr) => proceedAsync(
      (port) => nativeLibraryInstance.bindings.get_token_wallet_info(
        port,
        ptr,
        owner.toNativeUtf8().cast<Int8>(),
        rootTokenContract.toNativeUtf8().cast<Int8>(),
      ),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final info = TokenWalletInfo.fromJson(json);

  return info;
}
