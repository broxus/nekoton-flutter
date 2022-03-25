import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import '../../transport/transport.dart';
import 'models/existing_wallet_info.dart';

Future<List<ExistingWalletInfo>> findExistingWallets({
  required Transport transport,
  required String publicKey,
  required int workchainId,
}) async {
  final ptr = await transport.clonePtr();
  final transportType = transport.connectionData.type;

  final result = await executeAsync(
    (port) => NekotonFlutter.bindings.find_existing_wallets(
      port,
      ptr,
      transportType.index,
      publicKey.toNativeUtf8().cast<Int8>(),
      workchainId,
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as List<dynamic>;
  final jsonList = json.cast<Map<String, dynamic>>();
  final existingWallets = jsonList.map((e) => ExistingWalletInfo.fromJson(e)).toList();

  return existingWallets;
}
