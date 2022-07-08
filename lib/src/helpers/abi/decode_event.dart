import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/decoded_event.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/method_name.dart';

DecodedEvent? decodeEvent({
  required String messageBody,
  required String contractAbi,
  required MethodName event,
}) {
  final eventStr = jsonEncode(event);

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_decode_event(
          messageBody.toNativeUtf8().cast<Char>(),
          contractAbi.toNativeUtf8().cast<Char>(),
          eventStr.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result != null ? result as Map<String, dynamic> : null;
  final decodedEvent = json != null ? DecodedEvent.fromJson(json) : null;

  return decodedEvent;
}
