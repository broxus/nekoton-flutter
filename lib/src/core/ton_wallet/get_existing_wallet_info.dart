import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import '../../transport/transport.dart';
import 'models/existing_wallet_info.dart';

Future<ExistingWalletInfo> getExistingWalletInfo({
  required Transport transport,
  required String address,
}) async {
  final ptr = await transport.clonePtr();
  final transportType = transport.connectionData.type;

  final result = await executeAsync(
    (port) => NekotonFlutter.instance().bindings.nt_get_existing_wallet_info(
          port,
          ptr,
          transportType.index,
          address.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as Map<String, dynamic>;
  final existingWalletInfo = ExistingWalletInfo.fromJson(json);

  return existingWalletInfo;
}
