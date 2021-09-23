import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import '../provider/models/permission.dart';
import '../provider/models/permissions.dart';

part 'approval_request.freezed.dart';

@freezed
class ApprovalRequest with _$ApprovalRequest {
  const factory ApprovalRequest.permissions({
    required List<Permission> permissions,
    required Completer<Permissions> completer,
  }) = _Permissions;
}
