import 'package:collection/collection.dart';

import '../constants.dart';
import '../core/generic_contract/models/transaction_execution_options.dart';
import '../core/models/transaction.dart';
import '../core/ton_wallet/models/known_payload.dart';
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
import 'models/tokens_object.dart';
import 'models/unpack_from_cell_input.dart';
import 'models/unpack_from_cell_output.dart';
import 'models/unsubscribe_input.dart';

Future<RequestPermissionsOutput> requestPermissions({
  required String origin,
  required RequestPermissionsInput input,
}) async {
  final instance = await Nekoton.getInstance();

  return instance.permissionsController.requestPermissions(
    origin: origin,
    permissions: input.permissions,
  );
}

Future<void> disconnect({
  required String origin,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.removeOrigin(origin);
  await instance.subscriptionsController.removeOriginGenericContractSubscriptions(origin);
}

Future<SubscribeOutput> subscribe({
  required String origin,
  required SubscribeInput input,
}) async {
  final instance = await Nekoton.getInstance();

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

Future<void> unsubscribe({
  required String origin,
  required UnsubscribeInput input,
}) async {
  final instance = await Nekoton.getInstance();

  if (!helpers.validateAddress(input.address)) {
    throw InvalidAddressException();
  }

  await instance.subscriptionsController.removeGenericContractSubscription(
    origin: origin,
    address: input.address,
  );
}

Future<void> unsubscribeAll({
  required String origin,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.subscriptionsController.clearGenericContractsSubscriptions();
}

Future<GetProviderStateOutput> getProviderState({
  required String origin,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.subscriptionsController.clearGenericContractsSubscriptions();

  const version = kProviderVersion;
  final numericVersion = kProviderVersion.toInt();
  final selectedConnection = instance.connectionController.transport.connectionData.name;
  final permissions = instance.permissionsController.getPermissions(origin);
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
  required String origin,
  required GetFullContractStateInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final state = await instance.connectionController.getFullAccountState(address: input.address);

  return GetFullContractStateOutput(
    state: state,
  );
}

Future<GetTransactionsOutput> getTransactions({
  required String origin,
  required GetTransactionsInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final getTransactionsOutput = await instance.connectionController.getTransactions(
    address: input.address,
    continuation: input.continuation,
    limit: input.limit,
  );

  return getTransactionsOutput;
}

Future<RunLocalOutput> runLocal({
  required String origin,
  required RunLocalInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  FullContractState? contractState = input.cachedState;

  if (input.cachedState == null) {
    contractState = await instance.connectionController.transport.getFullAccountState(address: input.address);
  }

  if (contractState == null) {
    throw AccountNotFoundException();
  }

  if (!contractState.isDeployed || contractState.lastTransactionId == null) {
    throw AccountNotDeployedException();
  }

  return helpers.runLocal(
    genTimings: contractState.genTimings,
    lastTransactionId: contractState.lastTransactionId!,
    accountStuffBoc: contractState.boc,
    contractAbi: input.functionCall.abi,
    method: input.functionCall.method,
    input: input.functionCall.params,
  );
}

Future<GetExpectedAddressOutput> getExpectedAddress({
  required String origin,
  required GetExpectedAddressInput input,
}) async {
  final instance = await Nekoton.getInstance();

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
  required String origin,
  required PackIntoCellInput input,
}) async {
  final instance = await Nekoton.getInstance();

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
  required String origin,
  required UnpackFromCellInput input,
}) async {
  final instance = await Nekoton.getInstance();

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
  required String origin,
  required ExtractPublicKeyInput input,
}) async {
  final instance = await Nekoton.getInstance();

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
  required String origin,
  required CodeToTvcInput input,
}) async {
  final instance = await Nekoton.getInstance();

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
  required String origin,
  required SplitTvcInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  return helpers.splitTvc(input.tvc);
}

Future<EncodeInternalInputOutput> encodeInternalInput({
  required String origin,
  required EncodeInternalInputInput input,
}) async {
  final instance = await Nekoton.getInstance();

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
  required String origin,
  required DecodeInputInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  return helpers.decodeInput(
    messageBody: input.body,
    contractAbi: input.abi,
    method: input.method,
    internal: input.internal,
  );
}

Future<DecodeOutputOutput?> decodeOutput({
  required String origin,
  required DecodeOutputInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  return helpers.decodeOutput(
    messageBody: input.body,
    contractAbi: input.abi,
    method: input.method,
  );
}

Future<DecodeEventOutput?> decodeEvent({
  required String origin,
  required DecodeEventInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  return helpers.decodeEvent(
    messageBody: input.body,
    contractAbi: input.abi,
    event: input.event,
  );
}

Future<DecodeTransactionOutput?> decodeTransaction({
  required String origin,
  required DecodeTransactionInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  return helpers.decodeTransaction(
    transaction: input.transaction,
    contractAbi: input.abi,
    method: input.method,
  );
}

Future<DecodeTransactionEventsOutput> decodeTransactionEvents({
  required String origin,
  required DecodeTransactionEventsInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.tonClient],
  );

  final events = helpers.decodeTransactionEvents(
    transaction: input.transaction,
    contractAbi: input.abi,
  );

  return DecodeTransactionEventsOutput(
    events: events,
  );
}

Future<EstimateFeesOutput> estimateFees({
  required String origin,
  required EstimateFeesInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.accountInteraction],
  );

  final permissions = instance.permissionsController.getPermissions(origin);
  final allowedAccount = permissions.accountInteraction;

  if (allowedAccount?.address != input.sender) {
    throw PermissionsNotGrantedException();
  }

  final selectedAddress = allowedAccount!.address;
  final repackedRecipient = helpers.repackAddress(input.recipient);

  String? body;
  if (input.payload != null) {
    body = helpers.encodeInternalInput(
      contractAbi: input.payload!.abi,
      method: input.payload!.method,
      input: input.payload!.params,
    );
  }

  final tonWallet = instance.subscriptionsController.tonWallets.firstWhereOrNull((e) => e.address == selectedAddress);

  if (tonWallet == null) {
    throw TonWalletNotFoundException();
  }

  final unsignedMessage = await tonWallet.prepareTransfer(
    expiration: kDefaultMessageExpiration,
    destination: repackedRecipient,
    amount: int.parse(input.amount),
    body: body,
    isComment: false,
  );

  final fees = await tonWallet.estimateFees(unsignedMessage);

  return EstimateFeesOutput(
    fees: fees.toString(),
  );
}

Future<SendMessageOutput> sendMessage({
  required String origin,
  required SendMessageInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.accountInteraction],
  );

  final permissions = instance.permissionsController.getPermissions(origin);
  final allowedAccount = permissions.accountInteraction;

  if (allowedAccount?.address != input.sender) {
    throw PermissionsNotGrantedException();
  }

  final selectedAddress = allowedAccount!.address;
  final repackedRecipient = helpers.repackAddress(input.recipient);

  String? body;
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
    throw TonWalletNotFoundException();
  }

  final message = await tonWallet.prepareTransfer(
    expiration: kDefaultMessageExpiration,
    destination: repackedRecipient,
    amount: int.parse(input.amount),
    body: body,
    isComment: false,
  );

  final pendingTransaction = await tonWallet.send(
    message: message,
    password: password,
  );

  final transaction = await tonWallet.waitForTransaction(pendingTransaction);

  return SendMessageOutput(
    transaction: transaction,
  );
}

Future<SendExternalMessageOutput> sendExternalMessage({
  required String origin,
  required SendExternalMessageInput input,
}) async {
  final instance = await Nekoton.getInstance();

  await instance.permissionsController.checkPermissions(
    origin: origin,
    requiredPermissions: [Permission.accountInteraction],
  );

  final permissions = instance.permissionsController.getPermissions(origin);
  final allowedAccount = permissions.accountInteraction;

  if (allowedAccount?.publicKey != input.publicKey) {
    throw PermissionsNotGrantedException();
  }

  final selectedPublicKey = allowedAccount!.publicKey;
  final selectedAddress = allowedAccount.address;
  final repackedRecipient = helpers.repackAddress(input.recipient);

  final genericContract =
      instance.subscriptionsController.genericContracts[origin]?.firstWhereOrNull((e) => e.address == selectedAddress);

  if (genericContract == null) {
    throw GenericContractNotFoundException();
  }

  final message = helpers.createExternalMessage(
    dst: repackedRecipient,
    contractAbi: input.payload.abi,
    method: input.payload.method,
    stateInit: input.stateInit,
    input: input.payload.params,
    publicKey: selectedPublicKey,
    timeout: 30,
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
    message.nativeUnsignedMessage.free();
  } else {
    final pendingTransaction = await genericContract.send(
      message: message,
      publicKey: selectedPublicKey,
      password: password,
    );
    message.nativeUnsignedMessage.free();

    transaction = await genericContract.waitForTransaction(pendingTransaction);
  }

  TokensObject output;
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
