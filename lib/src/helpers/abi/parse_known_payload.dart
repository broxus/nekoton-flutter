import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../core/ton_wallet/models/known_payload.dart';
import '../../ffi_utils.dart';

KnownPayload? parseKnownPayload(String payload) {
  final result = executeSync(
    () => NekotonFlutter.bindings.nt_parse_known_payload(
      payload.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = optionalCStringToDart(result);
  final json = string != null ? jsonDecode(string) as Map<String, dynamic> : null;
  final knownPayload = json != null ? KnownPayload.fromJson(json) : null;

  return knownPayload;
}
