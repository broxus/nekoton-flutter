import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import 'models/splitted_tvc.dart';

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
