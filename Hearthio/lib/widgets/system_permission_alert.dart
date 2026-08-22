import 'package:flutter/material.dart';

import '../services/system_permission_service.dart';
import 'app_alert.dart';
import 'app_toast.dart';

Future<void> showSystemPermissionAlert(
  BuildContext context, {
  required SystemPermissionKind permission,
  required SystemPermissionState state,
  SystemPermissionGateway gateway =
      const MethodChannelSystemPermissionGateway(),
}) async {
  final openSettings = await showAppAlert<bool>(
    context,
    key: ValueKey('system-permission-${permission.name}-${state.name}'),
    title: '${_permissionName(permission)}权限不可用',
    message: _permissionGuidance(permission, state),
    actions: const [
      AppAlertAction(label: '稍后处理', result: false),
      AppAlertAction(
        label: '前往系统设置',
        result: true,
        key: Key('open-system-permission-settings'),
        isDefaultAction: true,
      ),
    ],
  );
  if (openSettings != true || !context.mounted) return;
  final opened = await gateway.openSettings();
  if (!opened && context.mounted) {
    AppToast.show(
      context,
      '请手动前往系统设置，为“家务志”开启${_permissionName(permission)}权限。',
      style: AppToastStyle.error,
    );
  }
}

String _permissionName(SystemPermissionKind permission) => switch (permission) {
  SystemPermissionKind.camera => '相机',
  SystemPermissionKind.photoLibrary => '照片',
  SystemPermissionKind.notifications => '通知',
};

String _permissionGuidance(
  SystemPermissionKind permission,
  SystemPermissionState state,
) {
  final name = _permissionName(permission);
  if (state == SystemPermissionState.unavailable) {
    return '当前无法读取$name权限状态。请稍后重试；如果你曾关闭权限，也可以前往系统设置检查。';
  }
  if (state == SystemPermissionState.notDetermined) {
    return '系统未能完成$name授权。请重试；如果仍不可用，请前往系统设置检查。';
  }
  return '$name权限尚未开启，因此暂时无法使用此功能。请前往系统设置允许“家务志”访问$name后再试。';
}
