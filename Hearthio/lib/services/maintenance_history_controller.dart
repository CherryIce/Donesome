import 'package:image_picker/image_picker.dart';

import '../models/care_item.dart';
import '../models/maintenance_record.dart';
import 'maintenance_execution_controller.dart';

abstract interface class MaintenanceHistoryController {
  Future<CareItem> updateMaintenanceRecord(
    String itemId,
    MaintenanceRecord record,
  );

  Future<CareItem> deleteMaintenanceRecord(String itemId, String recordId);

  Future<PhotoImportResult> importPhoto(ImageSource source);

  Future<void> discardImportedPhoto(String path);
}

class MaintenanceHistoryException implements Exception {
  const MaintenanceHistoryException(this.message);

  final String message;

  @override
  String toString() => 'MaintenanceHistoryException: $message';
}
