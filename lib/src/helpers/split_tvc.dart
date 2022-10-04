import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:tuple/tuple.dart';

Tuple2<String, String> splitTvc(String tvc) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_split_tvc(
          tvc.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as List<dynamic>;
  final list = json.cast<String>();
  final data = list.first;
  final code = list.last;

  return Tuple2(data, code);
}
