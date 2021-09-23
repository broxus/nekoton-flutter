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

  Stream<ApprovalRequest> get approvalStream => _approvalSubject.stream.distinct();

  Future<Permissions> requestApprovalForPermissions(List<Permission> permissions) async {
    final completer = Completer<Permissions>();

    final request = ApprovalRequest.permissions(
      permissions: permissions,
      completer: completer,
    );
    _approvalSubject.add(request);

    return completer.future;
  }
}
