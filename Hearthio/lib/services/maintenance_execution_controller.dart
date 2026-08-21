import 'package:image_picker/image_picker.dart';

import '../models/maintenance_completion.dart';

class PhotoImportResult {
  const PhotoImportResult._({this.path, this.error = false});
  const PhotoImportResult.cancelled() : this._();
  const PhotoImportResult.failed() : this._(error: true);
  const PhotoImportResult.success(String path) : this._(path: path);

  final String? path;
  final bool error;
}

abstract interface class MaintenanceExecutionController {
  Future<MaintenanceCompletionResult> completeMaintenance(
    MaintenanceCompletionDraft draft,
  );

  Future<PhotoImportResult> importPhoto(ImageSource source);

  Future<void> discardImportedPhoto(String path);
}
