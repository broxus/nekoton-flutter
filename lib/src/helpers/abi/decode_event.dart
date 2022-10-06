import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';
import 'models/decoded_event.dart';
import 'models/method_name.dart';

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

  final json = result != null ? result as Map<String, dynamic> : null;
  final decodedEvent = json != null ? DecodedEvent.fromJson(json) : null;

  return decodedEvent;
}
