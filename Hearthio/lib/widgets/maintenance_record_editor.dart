import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../l10n/maintenance_l10n.dart';
import '../models/maintenance_calendar.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_record.dart';
import '../services/maintenance_history_controller.dart';
import '../theme/app_theme.dart';
import 'app_back_button.dart';
import 'app_date_picker.dart';
import 'app_safe_area.dart';
import 'app_toast.dart';
import 'system_permission_alert.dart';

class MaintenanceRecordEditorPage extends StatefulWidget {
  const MaintenanceRecordEditorPage({
    super.key,
    required this.itemId,
    required this.record,
    required this.plan,
    required this.controller,
  });

  final String itemId;
  final MaintenanceRecord record;
  final MaintenancePlan? plan;
  final MaintenanceHistoryController controller;

  @override
  State<MaintenanceRecordEditorPage> createState() =>
      _MaintenanceRecordEditorPageState();
}

class _MaintenanceRecordEditorPageState
    extends State<MaintenanceRecordEditorPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _cost;
  late final TextEditingController _material;
  late final TextEditingController _note;
  late DateTime _completedAt;
  late final Set<String> _completedStepIds;
  late final List<String> _beforePhotos;
  late final List<String> _afterPhotos;
  final _newPhotoPaths = <String>{};
  bool _saving = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _cost = TextEditingController(
      text: record.cost == 0 ? '' : _money(record.cost),
    );
    _material = TextEditingController(text: record.materialName);
    _note = TextEditingController(text: record.note);
    _completedAt = maintenanceDateOnly(record.completedAt);
    _completedStepIds = record.completedStepIds.toSet();
    _beforePhotos = [...record.beforePhotos];
    _afterPhotos = [...record.afterPhotos];
  }

  @override
  void dispose() {
    _cost.dispose();
    _material.dispose();
    _note.dispose();
    if (!_saved) {
      for (final path in _newPhotoPaths) {
        unawaited(widget.controller.discardImportedPhoto(path));
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final checklist = [
      ...(widget.record.stepSnapshots ??
          captureMaintenanceStepSnapshots(
            widget.plan,
            widget.record.completedStepIds,
          )),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.editMaintenanceRecord),
      ),
      body: Form(
        key: _form,
        child: ListView(
          key: const PageStorageKey('maintenance-record-editor-scroll'),
          padding: appSafeScrollPadding(
            context,
            const EdgeInsets.fromLTRB(20, 14, 20, 40),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.palette.mist,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.linkedPlan,
                    style: TextStyle(color: context.palette.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${l10n.maintenancePlanTitleLabel(widget.record.kind)}${widget.plan == null && widget.record.planId != null ? l10n.originalPlanUnavailableSuffix : ''}',
                    key: const Key('record-editor-plan'),
                    style: TextStyle(
                      color: context.palette.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.recordPlanLinkImmutable,
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _RecordDateField(
              value: _completedAt,
              onChanged: (value) => setState(() => _completedAt = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('record-editor-cost'),
              controller: _cost,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) => _costValidator(l10n, value),
              decoration: InputDecoration(
                labelText: l10n.recordCostLabel,
                helperText: l10n.optionalZeroCostHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('record-editor-material'),
              controller: _material,
              enabled: !_saving,
              decoration: InputDecoration(labelText: l10n.materialNameLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('record-editor-note'),
              controller: _note,
              enabled: !_saving,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(labelText: l10n.notesLabel),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.executionSteps,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            if (checklist.isEmpty)
              Text(
                _completedStepIds.isEmpty
                    ? l10n.recordHasNoSteps
                    : l10n.historicalStepIdsOnly(_completedStepIds.length),
                style: TextStyle(color: context.palette.muted),
              )
            else
              ...checklist.map(
                (step) => CheckboxListTile(
                  key: ValueKey('record-editor-step-${step.id}'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _completedStepIds.contains(step.id),
                  title: Text(l10n.maintenanceStepTitleLabel(step.title)),
                  onChanged: _saving
                      ? null
                      : (selected) => setState(() {
                          if (selected == true) {
                            _completedStepIds.add(step.id);
                          } else {
                            _completedStepIds.remove(step.id);
                          }
                        }),
                ),
              ),
            const SizedBox(height: 18),
            _EditableRecordPhotos(
              title: l10n.beforePhotos,
              addKey: const Key('record-editor-add-before-photo'),
              photos: _beforePhotos,
              enabled: !_saving,
              onAdd: () => _addPhoto(before: true),
              onRemove: (path) => _removePhoto(path, before: true),
            ),
            const SizedBox(height: 18),
            _EditableRecordPhotos(
              title: l10n.afterPhotos,
              addKey: const Key('record-editor-add-after-photo'),
              photos: _afterPhotos,
              enabled: !_saving,
              onAdd: () => _addPhoto(before: false),
              onRemove: (path) => _removePhoto(path, before: false),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                key: const Key('record-editor-error'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('save-maintenance-record'),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? l10n.saving : l10n.saveRecord),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhoto({required bool before}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('record-editor-photo-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(sheet.l10n.takePhoto),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            ListTile(
              key: const Key('record-editor-photo-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(sheet.l10n.chooseFromPhotos),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final result = await widget.controller.importPhoto(source);
    if (!mounted) {
      if (result.path case final path?) {
        await widget.controller.discardImportedPhoto(path);
      }
      return;
    }
    final path = result.path;
    if (path != null) {
      setState(() {
        _newPhotoPaths.add(path);
        (before ? _beforePhotos : _afterPhotos).add(path);
      });
    } else if (result.permission case final permission?) {
      await showSystemPermissionAlert(
        context,
        permission: permission,
        state: result.permissionState!,
      );
    } else if (result.error) {
      AppToast.show(
        context,
        source == ImageSource.camera
            ? context.l10n.cameraOpenFailed
            : context.l10n.photoReadFailed,
        style: AppToastStyle.error,
      );
    }
  }

  void _removePhoto(String path, {required bool before}) {
    setState(() => (before ? _beforePhotos : _afterPhotos).remove(path));
    if (_newPhotoPaths.remove(path)) {
      unawaited(widget.controller.discardImportedPhoto(path));
    }
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final stepSnapshots =
          (widget.record.stepSnapshots ??
                  captureMaintenanceStepSnapshots(
                    widget.plan,
                    widget.record.completedStepIds,
                  ))
              .map(
                (step) => step.copyWith(
                  completed: _completedStepIds.contains(step.id),
                ),
              )
              .toList(growable: false);
      await widget.controller.updateMaintenanceRecord(
        widget.itemId,
        widget.record.copyWith(
          completedAt: _completedAt,
          cost: double.tryParse(_cost.text.trim()) ?? 0,
          materialName: _material.text.trim(),
          note: _note.text.trim(),
          stepSnapshots: stepSnapshots,
          beforePhotos: _beforePhotos,
          afterPhotos: _afterPhotos,
        ),
      );
      _saved = true;
      if (mounted) Navigator.pop(context, true);
    } on MaintenanceHistoryException {
      if (mounted) {
        setState(() => _error = context.l10n.maintenanceRecordSaveFailed);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.maintenanceRecordSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _RecordDateField extends StatelessWidget {
  const _RecordDateField({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    key: const Key('record-editor-date'),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: context.palette.border),
      borderRadius: BorderRadius.circular(16),
    ),
    title: Text(context.l10n.actualCompletionDate),
    subtitle: Text(context.l10n.formatDate(value)),
    trailing: const Icon(Icons.calendar_today_outlined),
    onTap: () async {
      final today = maintenanceDateOnly(DateTime.now());
      final initial = value.isAfter(today) ? today : value;
      final selected = await showAppDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: today,
      );
      if (selected != null) onChanged(selected);
    },
  );
}

class _EditableRecordPhotos extends StatelessWidget {
  const _EditableRecordPhotos({
    required this.title,
    required this.addKey,
    required this.photos,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final Key addKey;
  final List<String> photos;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton.icon(
            key: addKey,
            onPressed: enabled ? onAdd : null,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(context.l10n.commonAdd),
          ),
        ],
      ),
      if (photos.isEmpty)
        Text(
          context.l10n.noPhotosAdded,
          style: TextStyle(color: context.palette.muted),
        )
      else
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final path = photos[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(
                      File(path),
                      width: 104,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 104,
                        height: 92,
                        color: context.palette.mist,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 3,
                    right: 3,
                    child: IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      tooltip: context.l10n.removePhoto,
                      onPressed: enabled ? () => onRemove(path) : null,
                      icon: const Icon(Icons.close_rounded, size: 16),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
    ],
  );
}

String? _costValidator(AppLocalizations l10n, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final number = double.tryParse(text);
  if (number == null || !number.isFinite || number < 0) {
    return l10n.validationNonNegativeAmount;
  }
  return null;
}

String _money(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
