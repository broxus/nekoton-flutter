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
  final eventStr = jsonEncode(event);

  final result = executeSync(
    () => NekotonFlutter.bindings.nt_decode_event(
      messageBody.toNativeUtf8().cast<Char>(),
      contractAbi.toNativeUtf8().cast<Char>(),
      eventStr.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = optionalCStringToDart(result);
  final json = string != null ? jsonDecode(string) as Map<String, dynamic> : null;
  final decodedEvent = json != null ? DecodedEvent.fromJson(json) : null;

  return decodedEvent;
}
