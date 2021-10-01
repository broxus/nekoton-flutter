import 'package:collection/collection.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/known_payload.dart';
import 'package:nekoton_flutter/src/provider/models/event.dart';

import '../constants.dart';
import '../core/generic_contract/models/transaction_execution_options.dart';
import '../core/models/expiration.dart';
import '../core/models/transaction.dart';
import '../helpers/helpers.dart' as helpers;
import '../models/nekoton_exception.dart';
import '../nekoton.dart';
import '../utils.dart';
import 'models/code_to_tvc_input.dart';
import 'models/code_to_tvc_output.dart';
import 'models/contract_updates_subscription.dart';
import 'models/decode_event_input.dart';
import 'models/decode_event_output.dart';
import 'models/decode_input_input.dart';
import 'models/decode_input_output.dart';
import 'models/decode_output_input.dart';
import 'models/decode_output_output.dart';
import 'models/decode_transaction_events_input.dart';
import 'models/decode_transaction_events_output.dart';
import 'models/decode_transaction_input.dart';
import 'models/decode_transaction_output.dart';
import 'models/encode_internal_input_input.dart';
import 'models/encode_internal_input_output.dart';
import 'models/estimate_fees_input.dart';
import 'models/estimate_fees_output.dart';
import 'models/extract_public_key_input.dart';
import 'models/extract_public_key_output.dart';
import 'models/full_contract_state.dart';
import 'models/get_expected_address_input.dart';
import 'models/get_expected_address_output.dart';
import 'models/get_full_contract_state_input.dart';
import 'models/get_full_contract_state_output.dart';
import 'models/get_provider_state_output.dart';
import 'models/get_transactions_input.dart';
import 'models/get_transactions_output.dart';
import 'models/pack_into_cell_input.dart';
import 'models/pack_into_cell_output.dart';
import 'models/permission.dart';
import 'models/request_permissions_input.dart';
import 'models/request_permissions_output.dart';
import 'models/run_local_input.dart';
import 'models/run_local_output.dart';
import 'models/send_external_message_input.dart';
import 'models/send_external_message_output.dart';
import 'models/send_message_input.dart';
import 'models/send_message_output.dart';
import 'models/split_tvc_input.dart';
import 'models/split_tvc_output.dart';
import 'models/subscribe_input.dart';
import 'models/subscribe_output.dart';
import 'models/unpack_from_cell_input.dart';
import 'models/unpack_from_cell_output.dart';
import 'models/unsubscribe_input.dart';

Future<RequestPermissionsOutput> requestPermissions({
  required Nekoton instance,
  required String origin,
  required RequestPermissionsInput input,
}) async =>
    instance.permissionsController.requestPermissions(
      origin: origin,
      permissions: input.permissions,
    );

Future<void> disconnect({
  required Nekoton instance,
  required String origin,
}) async {
  await instance.permissionsController.removeOrigin(origin);
  instance.subscriptionsController.removeOriginGenericContractSubscriptions(origin);
}

Future<SubscribeOutput> subscribe({
  required Nekoton instance,
  required String origin,
  required SubscribeInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  if (!helpers.validateAddress(input.address)) {
    throw InvalidAddressException();
  }

  await instance.subscriptionsController.subscribeToGenericContract(
    origin: origin,
    address: input.address,
  );

  return const ContractUpdatesSubscription(
    state: true,
    transactions: true,
  );
}

void unsubscribe({
  required Nekoton instance,
  required String origin,
  required UnsubscribeInput input,
}) {
  if (!helpers.validateAddress(input.address)) {
    throw InvalidAddressException();
  }

  instance.subscriptionsController.removeGenericContractSubscription(
    origin: origin,
    address: input.address,
  );
}

void unsubscribeAll({
  required Nekoton instance,
  required String origin,
}) =>
    instance.subscriptionsController.clearGenericContractsSubscriptions();

Future<GetProviderStateOutput> getProviderState({
  required Nekoton instance,
  required String origin,
}) async {
  instance.subscriptionsController.clearGenericContractsSubscriptions();

  const version = kProviderVersion;
  final numericVersion = kProviderVersion.toInt();
  final selectedConnection = instance.connectionController.transport.connectionData.name;
  final permissions = await instance.permissionsController.getPermissions(origin);
  final subscriptions = instance.subscriptionsController.getOriginSubscriptions(origin);

  return GetProviderStateOutput(
    version: version,
    numericVersion: numericVersion,
    selectedConnection: selectedConnection,
    permissions: permissions,
    subscriptions: subscriptions,
  );
}

Future<GetFullContractStateOutput> getFullContractState({
  required Nekoton instance,
  required String origin,
  required GetFullContractStateInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final state = await instance.connectionController.transport.getFullAccountState(address: input.address);

  return GetFullContractStateOutput(
    state: state,
  );
}

Future<GetTransactionsOutput> getTransactions({
  required Nekoton instance,
  required String origin,
  required GetTransactionsInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final getTransactionsOutput = await instance.connectionController.transport.getTransactions(
    address: input.address,
    continuation: input.continuation,
    limit: input.limit,
  );

  return getTransactionsOutput;
}

Future<RunLocalOutput> runLocal({
  required Nekoton instance,
  required String origin,
  required RunLocalInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  FullContractState? contractState = input.cachedState;

  if (input.cachedState == null) {
    contractState = await instance.connectionController.transport.getFullAccountState(address: input.address);
  }

  if (contractState == null) {
    throw Exception("Account not found");
  }

  if (!contractState.isDeployed || contractState.lastTransactionId == null) {
    throw Exception("Account is not deployed");
  }

  final result = helpers.runLocal(
    genTimings: contractState.genTimings,
    lastTransactionId: contractState.lastTransactionId!,
    accountStuffBoc: contractState.boc,
    contractAbi: input.functionCall.abi,
    method: input.functionCall.method,
    input: input.functionCall.params,
  );

  return RunLocalOutput(
    output: result.output,
    code: result.code,
  );
}

Future<GetExpectedAddressOutput> getExpectedAddress({
  required Nekoton instance,
  required String origin,
  required GetExpectedAddressInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final address = helpers.getExpectedAddress(
    tvc: input.tvc,
    contractAbi: input.abi,
    workchainId: input.workchain,
    publicKey: input.publicKey,
    initData: input.initParams,
  );

  return GetExpectedAddressOutput(
    address: address,
  );
}

Future<PackIntoCellOutput> packIntoCell({
  required Nekoton instance,
  required String origin,
  required PackIntoCellInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final boc = helpers.packIntoCell(
    params: input.structure,
    tokens: input.data,
  );

  return PackIntoCellOutput(
    boc: boc,
  );
}

Future<UnpackFromCellOutput> unpackFromCell({
  required Nekoton instance,
  required String origin,
  required UnpackFromCellInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final data = helpers.unpackFromCell(
    params: input.structure,
    boc: input.boc,
    allowPartial: input.allowPartial,
  );

  return UnpackFromCellOutput(
    data: data,
  );
}

Future<ExtractPublicKeyOutput> extractPublicKey({
  required Nekoton instance,
  required String origin,
  required ExtractPublicKeyInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final publicKey = helpers.extractPublicKey(input.boc);

  return ExtractPublicKeyOutput(
    publicKey: publicKey,
  );
}

Future<CodeToTvcOutput> codeToTvc({
  required Nekoton instance,
  required String origin,
  required CodeToTvcInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final tvc = helpers.codeToTvc(input.code);

  return CodeToTvcOutput(
    tvc: tvc,
  );
}

Future<SplitTvcOutput> splitTvc({
  required Nekoton instance,
  required String origin,
  required SplitTvcInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final result = helpers.splitTvc(input.tvc);

  return SplitTvcOutput(
    data: result.data,
    code: result.code,
  );
}

Future<EncodeInternalInputOutput> encodeInternalInput({
  required Nekoton instance,
  required String origin,
  required EncodeInternalInputInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final boc = helpers.encodeInternalInput(
    contractAbi: input.abi,
    method: input.method,
    input: input.params,
  );

  return EncodeInternalInputOutput(
    boc: boc,
  );
}

Future<DecodeInputOutput?> decodeInput({
  required Nekoton instance,
  required String origin,
  required DecodeInputInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final result = helpers.decodeInput(
    messageBody: input.body,
    contractAbi: input.abi,
    method: input.method,
    internal: input.internal,
  );

  return result != null
      ? DecodeInputOutput(
          method: result.method,
          input: result.input,
        )
      : null;
}

Future<DecodeOutputOutput?> decodeOutput({
  required Nekoton instance,
  required String origin,
  required DecodeOutputInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final result = helpers.decodeOutput(
    messageBody: input.body,
    contractAbi: input.abi,
    method: input.method,
  );

  return result != null
      ? DecodeOutputOutput(
          method: result.method,
          output: result.output,
        )
      : null;
}

Future<DecodeEventOutput?> decodeEvent({
  required Nekoton instance,
  required String origin,
  required DecodeEventInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final result = helpers.decodeEvent(
    messageBody: input.body,
    contractAbi: input.abi,
    event: input.event,
  );

  return result != null
      ? DecodeEventOutput(
          event: result.event,
          data: result.data,
        )
      : null;
}

Future<DecodeTransactionOutput?> decodeTransaction({
  required Nekoton instance,
  required String origin,
  required DecodeTransactionInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final result = helpers.decodeTransaction(
    transaction: input.transaction,
    contractAbi: input.abi,
    method: input.method,
  );

  return result != null
      ? DecodeTransactionOutput(
          method: result.method,
          input: result.input,
          output: result.output,
        )
      : null;
}

Future<DecodeTransactionEventsOutput> decodeTransactionEvents({
  required Nekoton instance,
  required String origin,
  required DecodeTransactionEventsInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final events = helpers.decodeTransactionEvents(
    transaction: input.transaction,
    contractAbi: input.abi,
  );

  return DecodeTransactionEventsOutput(
    events: events
        .map((e) => Event(
              event: e.event,
              data: e.data,
            ))
        .toList(),
  );
}

Future<EstimateFeesOutput> estimateFees({
  required Nekoton instance,
  required String origin,
  required EstimateFeesInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.accountInteraction],
  );

  final permissions = await instance.permissionsController.getPermissions(origin);
  final allowedAccount = permissions.accountInteraction;

  if (allowedAccount?.address != input.sender) {
    throw Exception();
  }

  final selectedAddress = allowedAccount!.address;
  final repackedRecipient = helpers.repackAddress(input.recipient);

  String body = '';
  if (input.payload != null) {
    body = helpers.encodeInternalInput(
      contractAbi: input.payload!.abi,
      method: input.payload!.method,
      input: input.payload!.params,
    );
  }

  final tonWallet = instance.subscriptionsController.tonWallets.firstWhereOrNull((e) => e.address == selectedAddress);

  if (tonWallet == null) {
    throw Exception();
  }

  final unsignedMessage = await tonWallet.prepareTransfer(
    expiration: const Expiration.timeout(value: 60),
    destination: repackedRecipient,
    amount: int.parse(input.amount),
    body: body,
  );

  final fees = await tonWallet.estimateFees(unsignedMessage);

  return EstimateFeesOutput(
    fees: fees.toString(),
  );
}

Future<SendMessageOutput> sendMessage({
  required Nekoton instance,
  required String origin,
  required SendMessageInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.accountInteraction],
  );

  final permissions = await instance.permissionsController.getPermissions(origin);
  final allowedAccount = permissions.accountInteraction;

  if (allowedAccount?.address != input.sender) {
    throw Exception();
  }

  final selectedAddress = allowedAccount!.address;
  final repackedRecipient = helpers.repackAddress(input.recipient);

  String body = '';
  KnownPayload? knownPayload;
  if (input.payload != null) {
    body = helpers.encodeInternalInput(
      contractAbi: input.payload!.abi,
      method: input.payload!.method,
      input: input.payload!.params,
    );
    knownPayload = helpers.parseKnownPayload(body);
  }

  final password = await instance.approvalController.requestApprovalToSendMessage(
    origin: origin,
    sender: selectedAddress,
    recipient: repackedRecipient,
    amount: input.amount,
    bounce: input.bounce,
    payload: input.payload,
    knownPayload: knownPayload,
  );

  final tonWallet = instance.subscriptionsController.tonWallets.firstWhereOrNull((e) => e.address == selectedAddress);

  if (tonWallet == null) {
    throw Exception();
  }

  final message = await tonWallet.prepareTransfer(
    expiration: kDefaultMessageExpiration,
    destination: repackedRecipient,
    amount: int.parse(input.amount),
    body: body,
  );

  final pendingTransaction = await tonWallet.send(
    message: message,
    password: password,
  );

  final transaction = await tonWallet.onTransactionsFoundStream
      .expand((e) => e)
      .map((e) => e.transaction)
      .firstWhere((e) => e.id.hash == pendingTransaction.bodyHash)
      .timeout(const Duration(seconds: 60));

  return SendMessageOutput(
    transaction: transaction,
  );
}

Future<SendExternalMessageOutput> sendExternalMessage({
  required Nekoton instance,
  required String origin,
  required SendExternalMessageInput input,
}) async {
  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.accountInteraction],
  );

  final permissions = await instance.permissionsController.getPermissions(origin);
  final allowedAccount = permissions.accountInteraction;

  if (allowedAccount?.publicKey != input.publicKey) {
    throw Exception();
  }

  final selectedPublicKey = allowedAccount!.publicKey;
  final selectedAddress = allowedAccount.address;
  final repackedRecipient = helpers.repackAddress(input.recipient);

  final genericContract =
      instance.subscriptionsController.genericContracts[origin]?.firstWhereOrNull((e) => e.address == selectedAddress);

  if (genericContract == null) {
    throw Exception();
  }

  final message = helpers.createExternalMessage(
    dst: repackedRecipient,
    contractAbi: input.payload.abi,
    method: input.payload.method,
    stateInit: input.stateInit,
    input: input.payload.params,
    publicKey: selectedPublicKey,
    timeout: 60,
  );

  final password = await instance.approvalController.requestApprovalToCallContractMethod(
    origin: origin,
    selectedPublicKey: selectedPublicKey,
    repackedRecipient: repackedRecipient,
    payload: input.payload,
  );

  Transaction transaction;
  if (input.local == true) {
    transaction = await genericContract.executeTransactionLocally(
      message: message,
      publicKey: selectedPublicKey,
      password: password,
      options: const TransactionExecutionOptions(disableSignatureCheck: false),
    );
  } else {
    final pendingTransaction = await genericContract.send(
      message: message,
      publicKey: selectedPublicKey,
      password: password,
    );

    transaction = await genericContract.onTransactionsFoundStream
        .expand((e) => e)
        .firstWhere((e) => e.id.hash == pendingTransaction.bodyHash)
        .timeout(const Duration(seconds: 60));
  }

  dynamic output;
  try {
    final decoded = helpers.decodeTransaction(
      transaction: transaction,
      contractAbi: input.payload.abi,
      method: input.payload.method,
    );
    output = decoded?.output;
  } catch (_) {}

  return SendExternalMessageOutput(
    transaction: transaction,
    output: output,
  );
}
