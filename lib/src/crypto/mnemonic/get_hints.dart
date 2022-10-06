import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';

List<String> getHints(String input) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_get_hints(
          input.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as List;
  final hints = json.cast<String>();

  return hints;
}
