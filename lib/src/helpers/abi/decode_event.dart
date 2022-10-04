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
  final eventStr = event != null ? jsonEncode(event) : null;

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_decode_event(
          messageBody.toNativeUtf8().cast<Char>(),
          contractAbi.toNativeUtf8().cast<Char>(),
          eventStr?.toNativeUtf8().cast<Char>() ?? nullptr,
        ),
  );

  final json = result as Map<String, dynamic>?;
  final decodedEvent = json != null ? DecodedEvent.fromJson(json) : null;

  return decodedEvent;
}
