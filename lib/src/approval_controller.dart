import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'models/approval_request.dart';
import 'provider/models/permission.dart';
import 'provider/models/permissions.dart';

class ApprovalController {
  static ApprovalController? _instance;
  final _approvalSubject = PublishSubject<ApprovalRequest>();

  factory ApprovalController.instance() => _instance ??= ApprovalController._();

  ApprovalController._();

  Stream<ApprovalRequest> get approvalStream => _approvalSubject.stream;

  Future<Permissions> requestApprovalForPermissions({
    required String origin,
    required List<Permission> permissions,
  }) async {
    final completer = Completer<Permissions>();

    final request = ApprovalRequest.requestPermissions(
      origin: origin,
      permissions: permissions,
      completer: completer,
    );
    _approvalSubject.add(request);

    return completer.future;
  }

  Future<String> requestApprovalToSendMessage({
    required String origin,
    required String sender,
    required String recipient,
    required String amount,
    required bool bounce,
    required String payload,
    required String knownPayload,
  }) async {
    final completer = Completer<String>();

    final request = ApprovalRequest.sendMessage(
      origin: origin,
      sender: sender,
      recipient: recipient,
      amount: amount,
      bounce: bounce,
      payload: payload,
      knownPayload: knownPayload,
      completer: completer,
    );
    _approvalSubject.add(request);

    return completer.future;
  }

  Future<String> requestApprovalToCallContractMethod({
    required String origin,
    required String selectedPublicKey,
    required String repackedRecipient,
    required String payload,
  }) async {
    final completer = Completer<String>();

    final request = ApprovalRequest.callContractMethod(
      origin: origin,
      selectedPublicKey: selectedPublicKey,
      repackedRecipient: repackedRecipient,
      payload: payload,
      completer: completer,
    );
    _approvalSubject.add(request);

    return completer.future;
  }
}
