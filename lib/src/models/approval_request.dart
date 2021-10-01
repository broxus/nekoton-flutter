import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nekoton_flutter/src/core/ton_wallet/models/known_payload.dart';
import 'package:nekoton_flutter/src/provider/models/function_call.dart';

import '../provider/models/permission.dart';
import '../provider/models/permissions.dart';

part 'approval_request.freezed.dart';

@freezed
class ApprovalRequest with _$ApprovalRequest {
  const factory ApprovalRequest.requestPermissions({
    required String origin,
    required List<Permission> permissions,
    required Completer<Permissions> completer,
  }) = _RequestPermissions;

  const factory ApprovalRequest.sendMessage({
    required String origin,
    required String sender,
    required String recipient,
    required String amount,
    required bool bounce,
    required FunctionCall? payload,
    required KnownPayload? knownPayload,
    required Completer<String> completer,
  }) = _SendMessage;

  const factory ApprovalRequest.callContractMethod({
    required String origin,
    required String selectedPublicKey,
    required String repackedRecipient,
    required FunctionCall payload,
    required Completer<String> completer,
  }) = _CallContractMethod;
}
