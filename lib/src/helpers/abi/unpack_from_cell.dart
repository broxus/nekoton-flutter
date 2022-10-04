import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/abi_param.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/tokens_object.dart';

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

  final tokensObject = result as TokensObject;

  return tokensObject;
}
