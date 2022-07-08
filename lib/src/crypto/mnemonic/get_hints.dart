import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

List<String> getHints(String input) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_get_hints(
          input.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as List<dynamic>;
  final hints = json.cast<String>();

  return hints;
}
