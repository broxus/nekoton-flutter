import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/existing_wallet_info.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';

Future<ExistingWalletInfo> getExistingWalletInfo({
  required Transport transport,
  required String address,
}) async {
  final ptr = transport.ptr;
  final transportTypeStr = jsonEncode(transport.type.toString());

  final result = await executeAsync(
    (port) => NekotonFlutter.instance().bindings.nt_get_existing_wallet_info(
          port,
          ptr,
          transportTypeStr.toNativeUtf8().cast<Char>(),
          address.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as Map<String, dynamic>;
  final existingWalletInfo = ExistingWalletInfo.fromJson(json);

  return existingWalletInfo;
}
