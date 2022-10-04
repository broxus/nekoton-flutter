import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/abi_param.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/tokens_object.dart';

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

  final cell = result as String;

  return cell;
}
