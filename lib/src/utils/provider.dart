import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../core/models/transaction.dart';
import '../core/ton_wallet/models/known_payload.dart';
import '../core/unsigned_message.dart';
import '../ffi_utils.dart';
import 'models/abi_param.dart';
import 'models/decoded_event.dart';
import 'models/decoded_input.dart';
import 'models/decoded_output.dart';
import 'models/decoded_transaction.dart';
import 'models/decoded_transaction_event.dart';
import 'models/execution_output.dart';
import 'models/method_name.dart';
import 'models/splitted_tvc.dart';
import 'models/tokens_object.dart';

ExecutionOutput runLocal({
  required String accountStuffBoc,
  required String contractAbi,
  required String method,
  required TokensObject input,
}) {
  final inputStr = jsonEncode(input);

  final result = executeSync(
    () => bindings().run_local(
      accountStuffBoc.toNativeUtf8().cast<Int8>(),
      contractAbi.toNativeUtf8().cast<Int8>(),
      method.toNativeUtf8().cast<Int8>(),
      inputStr.toNativeUtf8().cast<Int8>(),
    ),
  );

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

  final result = executeSync(
    () => bindings().get_expected_address(
      tvc.toNativeUtf8().cast<Int8>(),
      contractAbi.toNativeUtf8().cast<Int8>(),
      workchainId ?? 0,
      publicKeyPtr,
      initDataStr.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);

  return string;
}

String packIntoCell({
  required List<AbiParam> params,
  required TokensObject tokens,
}) {
  final paramsStr = jsonEncode(params);
  final tokensStr = jsonEncode(tokens);

  final result = executeSync(
    () => bindings().pack_into_cell(
      paramsStr.toNativeUtf8().cast<Int8>(),
      tokensStr.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);

  return string;
}

TokensObject unpackFromCell({
  required List<AbiParam> params,
  required String boc,
  required bool allowPartial,
}) {
  final paramsStr = jsonEncode(params);

  final result = executeSync(
    () => bindings().unpack_from_cell(
      paramsStr.toNativeUtf8().cast<Int8>(),
      boc.toNativeUtf8().cast<Int8>(),
      allowPartial ? 1 : 0,
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as dynamic;
  final tokensObject = json as TokensObject;

  return tokensObject;
}

String extractPublicKey(String boc) {
  final result = executeSync(
    () => bindings().extract_public_key(
      boc.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);

  return string;
}

String codeToTvc(String code) {
  final result = executeSync(
    () => bindings().code_to_tvc(
      code.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);

  return string;
}

SplittedTvc splitTvc(String tvc) {
  final result = executeSync(
    () => bindings().split_tvc(
      tvc.toNativeUtf8().cast<Int8>(),
    ),
  );

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

  final result = executeSync(
    () => bindings().encode_internal_input(
      contractAbi.toNativeUtf8().cast<Int8>(),
      method.toNativeUtf8().cast<Int8>(),
      inputStr.toNativeUtf8().cast<Int8>(),
    ),
  );

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

  final result = executeSync(
    () => bindings().decode_input(
      messageBody.toNativeUtf8().cast<Int8>(),
      contractAbi.toNativeUtf8().cast<Int8>(),
      methodStr.toNativeUtf8().cast<Int8>(),
      internal ? 1 : 0,
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>?;

  final decodedInput = json != null ? DecodedInput.fromJson(json) : null;

  return decodedInput;
}

DecodedOutput? decodeOutput({
  required String messageBody,
  required String contractAbi,
  required MethodName method,
}) {
  final methodStr = jsonEncode(method);

  final result = executeSync(
    () => bindings().decode_output(
      messageBody.toNativeUtf8().cast<Int8>(),
      contractAbi.toNativeUtf8().cast<Int8>(),
      methodStr.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>?;

  final decodedOutput = json != null ? DecodedOutput.fromJson(json) : null;

  return decodedOutput;
}

DecodedEvent? decodeEvent({
  required String messageBody,
  required String contractAbi,
  required MethodName event,
}) {
  final eventStr = jsonEncode(event);

  final result = executeSync(
    () => bindings().decode_event(
      messageBody.toNativeUtf8().cast<Int8>(),
      contractAbi.toNativeUtf8().cast<Int8>(),
      eventStr.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>?;

  final decodedEvent = json != null ? DecodedEvent.fromJson(json) : null;

  return decodedEvent;
}

DecodedTransaction? decodeTransaction({
  required Transaction transaction,
  required String contractAbi,
  required MethodName method,
}) {
  final transactionStr = jsonEncode(transaction);
  final methodStr = jsonEncode(method);

  final result = executeSync(
    () => bindings().decode_transaction(
      transactionStr.toNativeUtf8().cast<Int8>(),
      contractAbi.toNativeUtf8().cast<Int8>(),
      methodStr.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>?;

  final decodedTransaction = json != null ? DecodedTransaction.fromJson(json) : null;

  return decodedTransaction;
}

List<DecodedTransactionEvent> decodeTransactionEvents({
  required Transaction transaction,
  required String contractAbi,
}) {
  final transactionStr = jsonEncode(transaction);

  final result = executeSync(
    () => bindings().decode_transaction_events(
      transactionStr.toNativeUtf8().cast<Int8>(),
      contractAbi.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);
  final list = jsonDecode(string) as List<dynamic>;
  final json = list.cast<Map<String, dynamic>>();
  final decodedTransactionEvents = json.map((e) => DecodedTransactionEvent.fromJson(e)).toList();

  return decodedTransactionEvents;
}

KnownPayload? parseKnownPayload(String payload) {
  final result = executeSync(
    () => bindings().parse_known_payload(
      payload.toNativeUtf8().cast<Int8>(),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>?;

  final knownPayload = json != null ? KnownPayload.fromJson(json) : null;

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

  final result = executeSync(
    () => bindings().create_external_message(
      dst.toNativeUtf8().cast<Int8>(),
      contractAbi.toNativeUtf8().cast<Int8>(),
      method.toNativeUtf8().cast<Int8>(),
      stateInitPtr,
      inputStr.toNativeUtf8().cast<Int8>(),
      publicKey.toNativeUtf8().cast<Int8>(),
      timeout,
    ),
  );

  final ptr = Pointer.fromAddress(result).cast<Void>();
  final unsignedMessage = UnsignedMessage(ptr);

  return unsignedMessage;
}
