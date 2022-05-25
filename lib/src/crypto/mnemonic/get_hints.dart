import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';

List<String> getHints(String input) {
  final result = executeSync(
    () => NekotonFlutter.bindings.nt_get_hints(
      input.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as List;
  final hints = json.cast<String>();

  return hints;
}
