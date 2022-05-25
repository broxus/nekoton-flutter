import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import 'models/splitted_tvc.dart';

SplittedTvc splitTvc(String tvc) {
  final result = executeSync(
    () => NekotonFlutter.bindings.nt_split_tvc(
      tvc.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final splittedTvc = SplittedTvc.fromJson(json);

  return splittedTvc;
}
