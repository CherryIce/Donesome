import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
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
  final l10n = context.l10n;
  final permissionName = _permissionName(l10n, permission);
  final openSettings = await showAppAlert<bool>(
    context,
    key: ValueKey('system-permission-${permission.name}-${state.name}'),
    title: l10n.permissionUnavailableTitle(permissionName),
    message: _permissionGuidance(l10n, permissionName, state),
    actions: [
      AppAlertAction(label: l10n.permissionLater, result: false),
      AppAlertAction(
        label: l10n.permissionOpenSettings,
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
      l10n.permissionOpenSettingsManually(permissionName),
      style: AppToastStyle.error,
    );
  }
}

String _permissionName(
  AppLocalizations l10n,
  SystemPermissionKind permission,
) => switch (permission) {
  SystemPermissionKind.camera => l10n.permissionCamera,
  SystemPermissionKind.notifications => l10n.permissionNotifications,
};

String _permissionGuidance(
  AppLocalizations l10n,
  String permissionName,
  SystemPermissionState state,
) {
  if (state == SystemPermissionState.unavailable) {
    return l10n.permissionStatusUnavailable(permissionName);
  }
  if (state == SystemPermissionState.notDetermined) {
    return l10n.permissionRequestIncomplete(permissionName);
  }
  return l10n.permissionDeniedGuidance(permissionName);
}
