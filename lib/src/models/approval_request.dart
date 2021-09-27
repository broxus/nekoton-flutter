import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';

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
    required String payload,
    required String knownPayload,
    required Completer<String> completer,
  }) = _SendMessage;

  const factory ApprovalRequest.callContractMethod({
    required String origin,
    required String selectedPublicKey,
    required String repackedRecipient,
    required String payload,
    required Completer<String> completer,
  }) = _CallContractMethod;
}
