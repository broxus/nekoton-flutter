import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import 'models/abi_param.dart';
import 'models/tokens_object.dart';

TokensObject unpackFromCell({
  required List<AbiParam> params,
  required String boc,
  required bool allowPartial,
}) {
  final paramsStr = jsonEncode(params);

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_unpack_from_cell(
          paramsStr.toNativeUtf8().cast<Char>(),
          boc.toNativeUtf8().cast<Char>(),
          allowPartial ? 1 : 0,
        ),
  );

  final json = result as dynamic;
  final tokensObject = json as TokensObject;

  return tokensObject;
}
