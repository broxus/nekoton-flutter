import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../core/models/gen_timings.dart';
import '../core/models/last_transaction_id.dart';
import '../core/models/native_unsigned_message.dart';
import '../core/models/transaction.dart';
import '../core/models/unsigned_message.dart';
import '../core/ton_wallet/models/known_payload.dart';
import '../ffi_utils.dart';
import '../native_library.dart';
import '../provider/models/abi_param.dart';
import '../provider/models/method_name.dart';
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
  required GenTimings genTimings,
  required LastTransactionId lastTransactionId,
  required String accountStuffBoc,
  required String contractAbi,
  required String method,
  required TokensObject input,
}) {
  final genTimingsStr = jsonEncode(genTimings);
  final lastTransactionIdStr = jsonEncode(lastTransactionId);
  final inputStr = jsonEncode(input);

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.run_local(
        genTimingsStr.toNativeUtf8().cast<Int8>(),
        lastTransactionIdStr.toNativeUtf8().cast<Int8>(),
        accountStuffBoc.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        method.toNativeUtf8().cast<Int8>(),
        inputStr.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final executionOutput = ExecutionOutput.fromJson(json);

  return executionOutput;
}

String getExpectedAddress({
  required String tvc,
  required String contractAbi,
  int? workchainId,
  String? publicKey,
  required TokensObject initData,
}) {
  final publicKeyPtr = publicKey?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final initDataStr = jsonEncode(initData);

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.get_expected_address(
        tvc.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        workchainId ?? 0,
        publicKeyPtr,
        initDataStr.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

String packIntoCell({
  required List<AbiParam> params,
  required TokensObject tokens,
}) {
  final paramsStr = jsonEncode(params);
  final tokensStr = jsonEncode(tokens);

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.pack_into_cell(
        paramsStr.toNativeUtf8().cast<Int8>(),
        tokensStr.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

TokensObject unpackFromCell({
  required List<AbiParam> params,
  required String boc,
  required bool allowPartial,
}) {
  final paramsStr = jsonEncode(params);

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.unpack_from_cell(
        paramsStr.toNativeUtf8().cast<Int8>(),
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
  required TokensObject input,
}) {
  final inputStr = jsonEncode(input);

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.encode_internal_input(
        contractAbi.toNativeUtf8().cast<Int8>(),
        method.toNativeUtf8().cast<Int8>(),
        inputStr.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);

  return string;
}

DecodedInput? decodeInput({
  required String messageBody,
  required String contractAbi,
  required MethodName method,
  required bool internal,
}) {
  final methodStr = jsonEncode(method);

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.decode_input(
        messageBody.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        methodStr.toNativeUtf8().cast<Int8>(),
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
  required MethodName method,
}) {
  final methodStr = jsonEncode(method);

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.decode_output(
        messageBody.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        methodStr.toNativeUtf8().cast<Int8>(),
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
  required MethodName event,
}) {
  final eventStr = jsonEncode(event);

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.decode_event(
        messageBody.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        eventStr.toNativeUtf8().cast<Int8>(),
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
  required Transaction transaction,
  required String contractAbi,
  required MethodName method,
}) {
  final transactionStr = jsonEncode(transaction);
  final methodStr = jsonEncode(method);

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.decode_transaction(
        transactionStr.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        methodStr.toNativeUtf8().cast<Int8>(),
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
  required Transaction transaction,
  required String contractAbi,
}) {
  final transactionStr = jsonEncode(transaction);

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.decode_transaction_events(
        transactionStr.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);
  final list = jsonDecode(string) as List<dynamic>;
  final json = list.cast<Map<String, dynamic>>();
  final decodedTransactionEvents = json.map((e) => DecodedTransactionEvent.fromJson(e)).toList();

  return decodedTransactionEvents;
}

KnownPayload? parseKnownPayload(String payload) {
  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.parse_known_payload(
        payload.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>?;

  if (json == null) {
    return null;
  }

  final knownPayload = KnownPayload.fromJson(json);

  return knownPayload;
}

UnsignedMessage createExternalMessage({
  required String dst,
  required String contractAbi,
  required String method,
  String? stateInit,
  required TokensObject input,
  required String publicKey,
  required int timeout,
}) {
  final inputStr = jsonEncode(input);
  final stateInitPtr = stateInit?.toNativeUtf8().cast<Int8>() ?? nullptr;

  final nativeLibrary = NativeLibrary.instance();
  final result = proceedSync(() => nativeLibrary.bindings.create_external_message(
        dst.toNativeUtf8().cast<Int8>(),
        contractAbi.toNativeUtf8().cast<Int8>(),
        method.toNativeUtf8().cast<Int8>(),
        stateInitPtr,
        inputStr.toNativeUtf8().cast<Int8>(),
        publicKey.toNativeUtf8().cast<Int8>(),
        timeout,
      ));

  final ptr = Pointer.fromAddress(result).cast<Void>();
  final nativeUnsignedMessage = NativeUnsignedMessage(ptr);
  final unsignedMessage = UnsignedMessage(nativeUnsignedMessage);

  return unsignedMessage;
}
