import 'package:flutter/services.dart';

enum SystemPermissionKind { camera, photoLibrary, notifications }

enum SystemPermissionState {
  notDetermined,
  granted,
  limited,
  denied,
  restricted,
  unavailable,
}

extension SystemPermissionStateAccess on SystemPermissionState {
  bool get isGranted =>
      this == SystemPermissionState.granted ||
      this == SystemPermissionState.limited;
}

abstract interface class SystemPermissionGateway {
  Future<SystemPermissionState> check(SystemPermissionKind permission);

  Future<SystemPermissionState> request(SystemPermissionKind permission);

  Future<bool> openSettings();
}

class MethodChannelSystemPermissionGateway implements SystemPermissionGateway {
  const MethodChannelSystemPermissionGateway();

  static const _channel = MethodChannel('hearthio/system_permissions');

  @override
  Future<SystemPermissionState> check(SystemPermissionKind permission) =>
      _invoke('check', permission);

  @override
  Future<SystemPermissionState> request(SystemPermissionKind permission) =>
      _invoke('request', permission);

  @override
  Future<bool> openSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<SystemPermissionState> _invoke(
    String method,
    SystemPermissionKind permission,
  ) async {
    try {
      final value = await _channel.invokeMethod<String>(method, {
        'permission': permission.name,
      });
      return SystemPermissionState.values.firstWhere(
        (state) => state.name == value,
        orElse: () => SystemPermissionState.unavailable,
      );
    } on PlatformException {
      return SystemPermissionState.unavailable;
    } on MissingPluginException {
      return SystemPermissionState.unavailable;
    }
  }
}

class SystemPermissionGuard {
  const SystemPermissionGuard(this.gateway);

  final SystemPermissionGateway gateway;

  Future<SystemPermissionState> ensure(SystemPermissionKind permission) async {
    final current = await gateway.check(permission);
    if (current != SystemPermissionState.notDetermined) return current;
    return gateway.request(permission);
  }
}
