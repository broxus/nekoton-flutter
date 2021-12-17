import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../ffi_utils.dart';
import '../../nekoton.dart';
import '../../transport/gql_transport.dart';
import 'models/existing_wallet_info.dart';

Future<List<ExistingWalletInfo>> findExistingWallets({
  required GqlTransport transport,
  required String publicKey,
  required int workchainId,
}) async {
  final result = await transport.nativeGqlTransport.use(
    (ptr) => proceedAsync(
      (port) => nativeLibraryInstance.bindings.find_existing_wallets(
        port,
        ptr,
        publicKey.toNativeUtf8().cast<Int8>(),
        workchainId,
      ),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as List<dynamic>;
  final jsonList = json.cast<Map<String, dynamic>>();
  final existingWallets = jsonList.map((e) => ExistingWalletInfo.fromJson(e)).toList();

  return existingWallets;
}
