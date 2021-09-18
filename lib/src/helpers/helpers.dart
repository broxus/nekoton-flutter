import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../ffi_utils.dart';
import '../native_library.dart';
import 'models/message_body_data.dart';

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

String runLocal({
  required String genTimings,
  required String lastTransactionId,
  required String accountStuffBoc,
  required String contractAbi,
  required String method,
  required String input,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.run_local(
        genTimings.toNativeUtf8().cast<Int8>(),
        lastTransactionId.toNativeUtf8().cast<Int8>(),
        accountStuffBoc.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        method.toNativeUtf8().cast<Int8>(),
        input.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String getExpectedAddress({
  required String tvc,
  required String contractAbi,
  required int workchainId,
  required String publicKey,
  required String initData,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.get_expected_address(
        tvc.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        workchainId,
        publicKey.toNativeUtf8().cast<Int8>(),
        initData.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String packIntoCell({
  required String params,
  required String tokens,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.pack_into_cell(
        params.toNativeUtf8().cast<Int8>(),
        tokens.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String unpackFromCell({
  required String params,
  required String boc,
  required bool allowPartial,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.unpack_from_cell(
        params.toNativeUtf8().cast<Int8>(),
        boc.toNativeUtf8().cast<Int8>(),
        allowPartial ? 1 : 0,
      ));

  final string = cStringToDart(result);

  return string;
}

String extractPublicKey({
  required String boc,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.extract_public_key(
        boc.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String codeToTvc({
  required String code,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.code_to_tvc(
        code.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String splitTvc({
  required String tvc,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.split_tvc(
        tvc.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String encodeInternalInput({
  required String contractAbi,
  required String method,
  required String input,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.encode_internal_input(
        contractAbi.toNativeUtf8().cast<Int8>(),
        method.toNativeUtf8().cast<Int8>(),
        input.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String decodeInput({
  required String messageBody,
  required String contractAbi,
  required String method,
  required bool internal,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.decode_input(
        messageBody.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        method.toNativeUtf8().cast<Int8>(),
        internal ? 1 : 0,
      ));

  final string = cStringToDart(result);

  return string;
}

String decodeOutput({
  required String messageBody,
  required String contractAbi,
  required String method,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.decode_output(
        messageBody.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        method.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String decodeEvent({
  required String messageBody,
  required String contractAbi,
  required String event,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.decode_event(
        messageBody.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        event.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String decodeTransaction({
  required String transaction,
  required String contractAbi,
  required String method,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.decode_transaction(
        transaction.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        method.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String decodeTransactionEvents({
  required String transaction,
  required String contractAbi,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.decode_transaction_events(
        transaction.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String createExternalMessage({
  required String dst,
  required String contractAbi,
  required String method,
  required String stateInit,
  required String input,
  required String publicKey,
  required int timeout,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.create_external_message(
        dst.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        method.toNativeUtf8().cast<Int8>(),
        stateInit.toNativeUtf8().cast<Int8>(),
        input.toNativeUtf8().cast<Int8>(),
        publicKey.toNativeUtf8().cast<Int8>(),
        timeout,
      ));

  final string = cStringToDart(result);

  return string;
}
