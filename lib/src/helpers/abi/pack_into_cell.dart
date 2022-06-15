import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import 'models/abi_param.dart';
import 'models/tokens_object.dart';

String packIntoCell({
  required List<AbiParam> params,
  required TokensObject tokens,
}) {
  final paramsStr = jsonEncode(params);
  final tokensStr = jsonEncode(tokens);

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_pack_into_cell(
          paramsStr.toNativeUtf8().cast<Char>(),
          tokensStr.toNativeUtf8().cast<Char>(),
        ),
  );

  return result as String;
}
