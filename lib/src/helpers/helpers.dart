import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../core/models/native_unsigned_message.dart';
import '../core/models/unsigned_message.dart';
import '../core/ton_wallet/models/known_payload.dart';
import '../ffi_utils.dart';
import '../native_library.dart';
import '../provider/models/tokens_object.dart';
import 'models/decoded_event.dart';
import 'models/decoded_input.dart';
import 'models/decoded_output.dart';
import 'models/decoded_transaction.dart';
import 'models/decoded_transaction_event.dart';
import 'models/execution_output.dart';
import 'models/message_body_data.dart';
import 'models/splitted_tvc.dart';

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

String repackAddress(String address) {
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

ExecutionOutput runLocal({
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
  final json = jsonDecode(string) as Map<String, dynamic>;
  final executionOutput = ExecutionOutput.fromJson(json);

  return executionOutput;
}

String getExpectedAddress({
  required String tvc,
  required String contractAbi,
  required int workchainId,
  String? publicKey,
  required String initData,
}) {
  final publicKeyPtr = publicKey?.toNativeUtf8().cast<Int8>() ?? nullptr;

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.get_expected_address(
        tvc.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        workchainId,
        publicKeyPtr,
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

TokensObject unpackFromCell({
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
  final json = jsonDecode(string) as dynamic;
  final tokensObject = json as TokensObject;

  return tokensObject;
}

String extractPublicKey(String boc) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.extract_public_key(
        boc.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String codeToTvc(String code) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.code_to_tvc(
        code.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

SplittedTvc splitTvc(String tvc) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.split_tvc(
        tvc.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final splittedTvc = SplittedTvc.fromJson(json);

  return splittedTvc;
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

DecodedInput? decodeInput({
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
  final json = jsonDecode(string) as Map<String, dynamic>?;

  if (json == null) {
    return null;
  }

  final decodedInput = DecodedInput.fromJson(json);

  return decodedInput;
}

DecodedOutput? decodeOutput({
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
  final json = jsonDecode(string) as Map<String, dynamic>?;

  if (json == null) {
    return null;
  }

  final decodedOutput = DecodedOutput.fromJson(json);

  return decodedOutput;
}

DecodedEvent? decodeEvent({
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
  final json = jsonDecode(string) as Map<String, dynamic>?;

  if (json == null) {
    return null;
  }

  final decodedEvent = DecodedEvent.fromJson(json);

  return decodedEvent;
}

DecodedTransaction? decodeTransaction({
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
  final json = jsonDecode(string) as Map<String, dynamic>?;

  if (json == null) {
    return null;
  }

  final decodedTransaction = DecodedTransaction.fromJson(json);

  return decodedTransaction;
}

List<DecodedTransactionEvent> decodeTransactionEvents({
  required String transaction,
  required String contractAbi,
}) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.decode_transaction_events(
        transaction.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);
  final list = jsonDecode(string) as List<dynamic>;
  final json = list.cast<Map<String, dynamic>>();
  final decodedTransactionEvents = json.map((e) => DecodedTransactionEvent.fromJson(e)).toList();

  return decodedTransactionEvents;
}

KnownPayload parseKnownPayload(String payload) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.parse_known_payload(
        payload.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final knownPayload = KnownPayload.fromJson(json);

  return knownPayload;
}

UnsignedMessage createExternalMessage({
  required String dst,
  required String contractAbi,
  required String method,
  String? stateInit,
  required String input,
  required String publicKey,
  required int timeout,
}) {
  final stateInitPtr = stateInit?.toNativeUtf8().cast<Int8>() ?? nullptr;

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.create_external_message(
        dst.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        method.toNativeUtf8().cast<Int8>(),
        stateInitPtr,
        input.toNativeUtf8().cast<Int8>(),
        publicKey.toNativeUtf8().cast<Int8>(),
        timeout,
      ));

  final ptr = Pointer.fromAddress(result).cast<Void>();
  final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
  final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

  return unsignedMessage;
}
