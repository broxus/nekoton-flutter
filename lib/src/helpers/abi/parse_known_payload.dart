import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/known_payload.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

KnownPayload? parseKnownPayload(String payload) {
  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_parse_known_payload(
          payload.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as Map<String, dynamic>?;
  final knownPayload = json != null ? KnownPayload.fromJson(json) : null;

  return knownPayload;
}
