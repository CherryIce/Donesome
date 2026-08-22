import 'package:image_picker/image_picker.dart';

import '../models/maintenance_completion.dart';
import 'system_permission_service.dart';

class PhotoImportResult {
  const PhotoImportResult._({
    this.path,
    this.error = false,
    this.permission,
    this.permissionState,
  });
  const PhotoImportResult.cancelled() : this._();
  const PhotoImportResult.failed() : this._(error: true);
  const PhotoImportResult.success(String path) : this._(path: path);
  const PhotoImportResult.permissionBlocked(
    SystemPermissionKind permission,
    SystemPermissionState state,
  ) : this._(permission: permission, permissionState: state);

  final String? path;
  final bool error;
  final SystemPermissionKind? permission;
  final SystemPermissionState? permissionState;
}

abstract interface class MaintenanceExecutionController {
  Future<MaintenanceCompletionResult> completeMaintenance(
    MaintenanceCompletionDraft draft,
  );

  Future<PhotoImportResult> importPhoto(ImageSource source);

  Future<void> discardImportedPhoto(String path);
}
