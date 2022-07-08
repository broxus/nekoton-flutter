import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/helpers/models/splitted_tvc.dart';

SplittedTvc splitTvc(String tvc) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_split_tvc(
          tvc.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as Map<String, dynamic>;
  final splittedTvc = SplittedTvc.fromJson(json);

  return splittedTvc;
}
