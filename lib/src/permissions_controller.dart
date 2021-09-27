import 'approval_controller.dart';
import 'preferences.dart';
import 'provider/models/permission.dart';
import 'provider/models/permissions.dart';

class PermissionsController {
  static PermissionsController? _instance;
  final _approvalController = ApprovalController.instance();
  late final Preferences _preferences;

  PermissionsController._();

  static Future<PermissionsController> getInstance() async {
    if (_instance == null) {
      final instance = PermissionsController._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Future<Permissions> requestPermissions({
    required String origin,
    required List<Permission> permissions,
  }) async {
    final requested = await _approvalController.requestApprovalForPermissions(
      origin: origin,
      permissions: permissions,
    );

    await _preferences.setPermissions(
      origin: origin,
      permissions: requested,
    );

    return requested;
  }

  Future<void> removeOrigin(String origin) => _preferences.deletePermissions(origin);

  Future<Permissions?> getPermissions(String origin) async => _preferences.getPermissions(origin);

  Future<void> checkPermissions({
    required String origin,
    required List<Permission> requiredPermissions,
  }) async {
    final permissions = await getPermissions(origin);

    if (permissions == null) {
      throw Exception();
    }

    for (final requiredPermission in requiredPermissions) {
      switch (requiredPermission) {
        case Permission.tonClient:
          if (permissions.tonClient == null || permissions.tonClient == false) {
            throw Exception();
          }
          break;
        case Permission.accountInteraction:
          if (permissions.accountInteraction == null) {
            throw Exception();
          }
          break;
      }
    }
  }

  Future<void> _initialize() async {
    _preferences = await Preferences.getInstance();
  }
}
