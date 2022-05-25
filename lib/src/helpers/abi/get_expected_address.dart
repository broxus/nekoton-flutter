import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import 'models/tokens_object.dart';

String getExpectedAddress({
  required String tvc,
  required String contractAbi,
  required int workchainId,
  String? publicKey,
  required TokensObject initData,
}) {
  final initDataStr = jsonEncode(initData);

  final result = executeSync(
    () => NekotonFlutter.bindings.nt_get_expected_address(
      tvc.toNativeUtf8().cast<Char>(),
      contractAbi.toNativeUtf8().cast<Char>(),
      workchainId,
      publicKey?.toNativeUtf8().cast<Char>() ?? nullptr,
      initDataStr.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = cStringToDart(result);

  return string;
}
