import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/accounts_storage/models/wallet_type.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/existing_wallet_info.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';

Future<List<ExistingWalletInfo>> findExistingWallets({
  required Transport transport,
  required String publicKey,
  required int workchainId,
  required List<WalletType> walletTypes,
}) async {
  final ptr = transport.ptr;
  final transportTypeStr = jsonEncode(transport.type.toString());
  final walletTypesStr = jsonEncode(walletTypes);

  final result = await executeAsync(
    (port) => NekotonFlutter.instance().bindings.nt_find_existing_wallets(
          port,
          ptr,
          transportTypeStr.toNativeUtf8().cast<Char>(),
          publicKey.toNativeUtf8().cast<Char>(),
          workchainId,
          walletTypesStr.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as List<dynamic>;
  final list = json.cast<Map<String, dynamic>>();
  final existingWallets = list.map((e) => ExistingWalletInfo.fromJson(e)).toList();

  return existingWallets;
}
