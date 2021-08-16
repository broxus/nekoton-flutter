import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../core/models/message_body_data.dart';
import '../ffi_utils.dart';
import '../native_library.dart';

String packStdSmcAddr({
  required bool base64Url,
  required String addr,
  required bool bounceable,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.pack_std_smc_addr(
        base64Url ? 1 : 0,
        addr.toNativeUtf8().cast<Int8>(),
        bounceable ? 1 : 0,
      ));

  final string = cStringToDart(result);

  return string;
}

String unpackStdSmcAddr({
  required String packed,
  required bool base64Url,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.unpack_std_smc_addr(
        packed.toNativeUtf8().cast<Int8>(),
        base64Url ? 1 : 0,
      ));

  final string = cStringToDart(result);

  return string;
}

bool validateAddress(String address) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.validate_address(address.toNativeUtf8().cast<Int8>()));

  final isValid = result != 0;

  return isValid;
}

String repackAddress({
  required String address,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.repack_address(address.toNativeUtf8().cast<Int8>()));

  final string = cStringToDart(result);

  return string;
}

MessageBodyData? parseMessageBodyData(String data) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.parse_message_body_data(data.toNativeUtf8().cast<Int8>()));

  if (result != 0) {
    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final messageBodyData = MessageBodyData.fromJson(json);

    return messageBodyData;
  } else {
    return null;
  }
}
