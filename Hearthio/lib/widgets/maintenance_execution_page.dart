import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../l10n/catalog_l10n.dart';
import '../l10n/l10n.dart';
import '../l10n/maintenance_l10n.dart';
import '../models/maintenance_calendar.dart';
import '../models/maintenance_completion.dart';
import '../models/maintenance_task.dart';
import '../services/maintenance_execution_controller.dart';
import '../theme/app_theme.dart';
import 'app_back_button.dart';
import 'app_date_picker.dart';
import 'app_safe_area.dart';
import 'app_toast.dart';
import 'system_permission_alert.dart';

class MaintenanceExecutionPage extends StatefulWidget {
  const MaintenanceExecutionPage({
    super.key,
    required this.controller,
    required this.task,
  });

  final MaintenanceExecutionController controller;
  final MaintenanceTask task;

  @override
  State<MaintenanceExecutionPage> createState() =>
      _MaintenanceExecutionPageState();
}

class _MaintenanceExecutionPageState extends State<MaintenanceExecutionPage> {
  final _form = GlobalKey<FormState>();
  final _cost = TextEditingController();
  final _material = TextEditingController();
  final _note = TextEditingController();
  final _completedStepIds = <String>{};
  final _beforePhotos = <String>[];
  final _afterPhotos = <String>[];
  late final String _operationId;
  late DateTime _completedAt;
  bool _submitting = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _operationId = DateTime.now().microsecondsSinceEpoch.toString();
    _completedAt = maintenanceDateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _cost.dispose();
    _material.dispose();
    _note.dispose();
    if (!_saved) {
      for (final path in [..._beforePhotos, ..._afterPhotos]) {
        unawaited(widget.controller.discardImportedPhoto(path));
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final task = widget.task;
    final plan = task.plan;
    final steps = [...plan.checklist]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final currentStepIndex = steps.indexWhere(
      (step) => !_completedStepIds.contains(step.id),
    );
    final executionStarted = _completedStepIds.isNotEmpty;
    final allStepsComplete = steps.isEmpty || currentStepIndex == -1;
    final beforePhotosEditable = !executionStarted && !_submitting;
    final afterPhotosEditable = allStepsComplete && !_submitting;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: const AppBackButton(),
        title: Text(l10n.startMaintenance),
      ),
      body: Form(
        key: _form,
        child: ListView(
          key: const PageStorageKey('maintenance-execution-scroll'),
          padding: appSafeScrollPadding(
            context,
            const EdgeInsets.fromLTRB(20, 14, 20, 40),
          ),
          children: [
            _ExecutionTaskSummary(task: task),
            const SizedBox(height: 12),
            _BeforePhotoRecordCard(
              photos: _beforePhotos,
              editable: beforePhotosEditable,
              executionStarted: executionStarted,
              onTap: beforePhotosEditable || _beforePhotos.isNotEmpty
                  ? () => _showPhotoSheet(
                      before: true,
                      editable: beforePhotosEditable,
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            Text(
              l10n.executionSteps,
              style: TextStyle(
                color: context.palette.primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            if (steps.isEmpty)
              Text(
                l10n.executionNoPresetSteps,
                style: TextStyle(color: context.palette.muted),
              )
            else
              ...List.generate(steps.length, (index) {
                final step = steps[index];
                final completed = _completedStepIds.contains(step.id);
                return _ExecutionTimelineStep(
                  key: ValueKey('execution-step-${step.id}'),
                  number: index + 1,
                  title: context.l10n.maintenanceStepTitleLabel(step.title),
                  description: context.l10n.maintenanceStepDescriptionLabel(
                    step.description,
                  ),
                  completed: completed,
                  current: !completed && index == currentStepIndex,
                  isLast: index == steps.length - 1,
                  enabled: !_submitting,
                  onTap: () => setState(() {
                    if (completed) {
                      _completedStepIds.remove(step.id);
                    } else {
                      _completedStepIds.add(step.id);
                    }
                  }),
                );
              }),
            const SizedBox(height: 12),
            Divider(color: context.palette.border),
            const SizedBox(height: 12),
            Text(
              l10n.optionalRecordSection,
              style: TextStyle(
                color: context.palette.primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _RecordShortcut(
                    key: const Key('execution-record-date'),
                    icon: Icons.calendar_today_outlined,
                    label: l10n.dateLabel,
                    caption: l10n.dateMonthDay(
                      _completedAt.month,
                      _completedAt.day,
                    ),
                    enabled: !_submitting,
                    onTap: _editCompletionDate,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _RecordShortcut(
                    key: const Key('execution-record-cost'),
                    icon: Icons.currency_yen_rounded,
                    label: l10n.costLabel,
                    caption: _cost.text.trim().isEmpty
                        ? l10n.optional
                        : '¥${_cost.text.trim()}',
                    enabled: !_submitting,
                    onTap: _editCost,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _RecordShortcut(
                    key: const Key('execution-record-material'),
                    icon: Icons.inventory_2_outlined,
                    label: l10n.materialLabel,
                    caption: _material.text.trim().isEmpty
                        ? l10n.modelOrName
                        : l10n.completedField,
                    enabled: !_submitting,
                    onTap: _editMaterial,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _RecordShortcut(
                    key: const Key('execution-record-note'),
                    icon: Icons.note_alt_outlined,
                    label: l10n.notesLabel,
                    caption: _note.text.trim().isEmpty
                        ? l10n.optional
                        : l10n.completedField,
                    enabled: !_submitting,
                    onTap: _editNote,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _AfterPhotoComparisonCard(
              beforePhotos: _beforePhotos,
              afterPhotos: _afterPhotos,
              editable: afterPhotosEditable,
              onTap: afterPhotosEditable || _afterPhotos.isNotEmpty
                  ? () => _showPhotoSheet(
                      before: false,
                      editable: afterPhotosEditable,
                    )
                  : null,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      bottomNavigationBar: _CompletionActionBar(
        enabled: allStepsComplete && !_submitting,
        submitting: _submitting,
        error: _error,
        onPressed: _submit,
      ),
    );
  }

  DateTime get _firstCompletionDate {
    final previous = widget.task.plan.lastCompletedAt;
    if (previous == null || previous.isBefore(DateTime(2000))) {
      return DateTime(2000);
    }
    return maintenanceDateOnly(previous);
  }

  Future<void> _editCompletionDate() async {
    final selected = await showAppDatePicker(
      context: context,
      initialDate: _completedAt,
      firstDate: _firstCompletionDate,
      lastDate: maintenanceDateOnly(DateTime.now()),
    );
    if (selected != null && mounted) {
      setState(() => _completedAt = selected);
    }
  }

  Future<void> _editCost() => _editTextRecord(
    title: context.l10n.recordCostTitle,
    label: context.l10n.recordCostLabel,
    helperText: context.l10n.optionalZeroCostHint,
    fieldKey: const Key('execution-cost'),
    controller: _cost,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (value) => _completionCostValidator(context.l10n, value),
  );

  Future<void> _editMaterial() => _editTextRecord(
    title: context.l10n.recordMaterialTitle,
    label: context.l10n.materialNameLabel,
    helperText: context.l10n.materialExample,
    fieldKey: const Key('execution-material'),
    controller: _material,
  );

  Future<void> _editNote() => _editTextRecord(
    title: context.l10n.addNotesTitle,
    label: context.l10n.notesLabel,
    helperText: context.l10n.notesHelper,
    fieldKey: const Key('execution-note'),
    controller: _note,
    minLines: 3,
    maxLines: 5,
  );

  Future<void> _editTextRecord({
    required String title,
    required String label,
    required String helperText,
    required Key fieldKey,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
  }) async {
    final sheetForm = GlobalKey<FormState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Form(
              key: sheetForm,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: sheetContext.palette.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: sheetContext.l10n.commonClose,
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: fieldKey,
                    controller: controller,
                    keyboardType: keyboardType,
                    validator: validator,
                    minLines: minLines,
                    maxLines: maxLines,
                    decoration: InputDecoration(
                      labelText: label,
                      helperText: helperText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    key: const Key('record-field-done'),
                    onPressed: () {
                      if (!(sheetForm.currentState?.validate() ?? false)) {
                        return;
                      }
                      Navigator.pop(sheetContext);
                    },
                    child: Text(sheetContext.l10n.commonDone),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _showPhotoSheet({
    required bool before,
    required bool editable,
  }) async {
    final photos = before ? _beforePhotos : _afterPhotos;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        before
                            ? sheetContext.l10n.beforePhotoCaptureTitle
                            : sheetContext.l10n.afterPhotoCaptureTitle,
                        style: TextStyle(
                          color: sheetContext.palette.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: sheetContext.l10n.commonClose,
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _PhotoSection(
                  title: before
                      ? sheetContext.l10n.beforePhotos
                      : sheetContext.l10n.afterPhotos,
                  addKey: Key(
                    before
                        ? 'add-before-maintenance-photo'
                        : 'add-after-maintenance-photo',
                  ),
                  photos: photos,
                  enabled: editable,
                  onAdd: () async {
                    await _addPhoto(before: before);
                    if (sheetContext.mounted) setSheetState(() {});
                  },
                  onRemove: (path) {
                    _removePhoto(path, before: before);
                    setSheetState(() {});
                  },
                ),
                if (!editable) ...[
                  const SizedBox(height: 16),
                  Text(
                    before
                        ? sheetContext.l10n.beforePhotosLocked
                        : sheetContext.l10n.afterPhotosTemporarilyLocked,
                    style: TextStyle(
                      color: sheetContext.palette.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _addPhoto({required bool before}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('execution-photo-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(sheet.l10n.takePhoto),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            ListTile(
              key: const Key('execution-photo-gallery'),
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
    if (result.path != null) {
      setState(() {
        (before ? _beforePhotos : _afterPhotos).add(result.path!);
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
    unawaited(widget.controller.discardImportedPhoto(path));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final allStepIds = widget.task.plan.checklist
        .map((step) => step.id)
        .toSet();
    if (!_completedStepIds.containsAll(allStepIds)) {
      return;
    }
    final costError = _completionCostValidator(context.l10n, _cost.text);
    if (costError != null) {
      setState(() => _error = costError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.controller.completeMaintenance(
        MaintenanceCompletionDraft(
          operationId: _operationId,
          itemId: widget.task.item.id,
          planId: widget.task.plan.id,
          completedAt: _completedAt,
          cost: double.tryParse(_cost.text.trim()) ?? 0,
          materialName: _material.text,
          note: _note.text,
          completedStepIds: widget.task.plan.checklist
              .where((step) => _completedStepIds.contains(step.id))
              .map((step) => step.id)
              .toList(growable: false),
          beforePhotos: _beforePhotos,
          afterPhotos: _afterPhotos,
        ),
      );
      _saved = true;
      if (!mounted) return;
      final closeExecution = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MaintenanceCompletionResultPage(result: result),
        ),
      );
      if (closeExecution == true && mounted) {
        Navigator.pop(context, true);
      }
    } on MaintenanceCompletionException {
      if (mounted) {
        setState(() => _error = context.l10n.maintenanceCompletionSaveFailed);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.maintenanceCompletionSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class MaintenanceCompletionResultPage extends StatelessWidget {
  const MaintenanceCompletionResultPage({super.key, required this.result});

  final MaintenanceCompletionResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.maintenanceCompletedTitle),
        ),
        body: ListView(
          padding: appSafeScrollPadding(context, const EdgeInsets.all(24)),
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 72,
              color: context.palette.success,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.maintenanceArchived,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            _ResultRow(
              label: l10n.completionTime,
              value: l10n.formatDate(result.record.completedAt),
            ),
            _ResultRow(
              label: l10n.thisCost,
              value: '¥${_money(result.record.cost)}',
            ),
            _ResultRow(
              label: l10n.nextPlan,
              value: l10n.formatDate(result.plan.dueDate!),
            ),
            _ResultRow(
              label: l10n.reminder,
              value: l10n.reminderDaysEarly(result.plan.reminderLeadDays),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.completionLifecycleHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.muted, height: 1.45),
            ),
            if (!result.notificationScheduled) ...[
              const SizedBox(height: 16),
              Container(
                key: const Key('completion-notification-warning'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.palette.warningSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  l10n.notificationRescheduleFailed,
                  style: TextStyle(
                    color: context.palette.warningStrong,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              key: const Key('finish-maintenance-result'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.viewLifecycle),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExecutionTaskSummary extends StatelessWidget {
  const _ExecutionTaskSummary({required this.task});

  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    final showsPurifier =
        task.item.name.contains('净水') || task.plan.title.contains('滤芯');
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: context.palette.mist,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 52,
            child: showsPurifier
                ? Image.asset(
                    'assets/home/dashboard-purifier-icon.png',
                    fit: BoxFit.contain,
                    semanticLabel: context.l10n.templateSceneWaterPurifier,
                  )
                : Icon(
                    Icons.home_repair_service_outlined,
                    size: 36,
                    color: context.palette.primary,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.itemNameLabel(
                    id: task.item.id,
                    isSample: task.item.isSample,
                    name: task.item.name,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.maintenancePlanTitleLabel(task.plan.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.originalPlanDate(
                    context.l10n.formatDate(task.dueDate),
                  ),
                  key: const Key('execution-original-status'),
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: context.palette.successSurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              context.l10n.maintenanceTimingLabel(task.status),
              style: TextStyle(
                color: context.palette.successStrong,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeforePhotoRecordCard extends StatelessWidget {
  const _BeforePhotoRecordCard({
    required this.photos,
    required this.editable,
    required this.executionStarted,
    required this.onTap,
  });

  final List<String> photos;
  final bool editable;
  final bool executionStarted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = photos.isNotEmpty;
    final status = hasPhotos
        ? context.l10n.photosRecordedCount(photos.length)
        : executionStarted
        ? context.l10n.noPhotosThisTime
        : context.l10n.beforePhotoPrompt;
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: context.l10n.beforePhotoSemantic(
        status,
        executionStarted ? context.l10n.beforePhotoLockedSemanticSuffix : '',
      ),
      excludeSemantics: true,
      child: Material(
        color: context.palette.softSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: const Key('execution-before-photo-entry'),
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                _PhotoStateThumbnail(
                  photos: photos,
                  icon: Icons.photo_camera_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.beforePhotoOptional,
                        style: TextStyle(
                          color: context.palette.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.palette.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (editable)
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: context.palette.successStrong,
                  )
                else if (hasPhotos)
                  Icon(
                    Icons.lock_outline_rounded,
                    color: context.palette.muted,
                    size: 21,
                  )
                else
                  Icon(
                    Icons.check_rounded,
                    color: context.palette.subtle,
                    size: 21,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AfterPhotoComparisonCard extends StatelessWidget {
  const _AfterPhotoComparisonCard({
    required this.beforePhotos,
    required this.afterPhotos,
    required this.editable,
    required this.onTap,
  });

  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final bool editable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasAfterPhotos = afterPhotos.isNotEmpty;
    final helper = editable
        ? context.l10n.afterPhotoReadyHint
        : hasAfterPhotos
        ? context.l10n.afterPhotoReopenedHint
        : context.l10n.afterPhotoWaitingHint;
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: context.l10n.afterPhotoSemantic(
        afterPhotos.isEmpty
            ? helper
            : context.l10n.photosRecordedCount(afterPhotos.length),
      ),
      excludeSemantics: true,
      child: Material(
        color: context.palette.paper,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: const Key('execution-after-photo-entry'),
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.afterPhotoOptional,
                        style: TextStyle(
                          color: context.palette.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      editable
                          ? Icons.add_a_photo_outlined
                          : hasAfterPhotos
                          ? Icons.lock_outline_rounded
                          : Icons.lock_clock_outlined,
                      color: editable
                          ? context.palette.successStrong
                          : context.palette.subtle,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  helper,
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: _PhotoComparisonSlot(
                        title: context.l10n.beforeLabel,
                        photos: beforePhotos,
                        emptyLabel: context.l10n.notRecorded,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: context.palette.success,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: _PhotoComparisonSlot(
                        title: context.l10n.afterLabel,
                        photos: afterPhotos,
                        emptyLabel: editable
                            ? context.l10n.tapToAdd
                            : context.l10n.waitingForCompletion,
                        emphasized: editable,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoComparisonSlot extends StatelessWidget {
  const _PhotoComparisonSlot({
    required this.title,
    required this.photos,
    required this.emptyLabel,
    this.emphasized = false,
  });

  final String title;
  final List<String> photos;
  final String emptyLabel;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: emphasized ? context.palette.mist : context.palette.softSurface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        _PhotoStateThumbnail(
          photos: photos,
          icon: emphasized ? Icons.add_a_photo_outlined : Icons.image_outlined,
          size: 46,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  color: context.palette.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                photos.isEmpty
                    ? emptyLabel
                    : context.l10n.photoCount(photos.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.palette.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PhotoStateThumbnail extends StatelessWidget {
  const _PhotoStateThumbnail({
    required this.photos,
    required this.icon,
    this.size = 48,
  });

  final List<String> photos;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.palette.mist,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: context.palette.primary, size: size * .5),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Image.file(
        File(photos.first),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: context.palette.mist,
          child: Icon(Icons.image_outlined, color: context.palette.primary),
        ),
      ),
    );
  }
}

class _ExecutionTimelineStep extends StatelessWidget {
  const _ExecutionTimelineStep({
    super.key,
    required this.number,
    required this.title,
    required this.description,
    required this.completed,
    required this.current,
    required this.isLast,
    required this.enabled,
    required this.onTap,
  });

  final int number;
  final String title;
  final String description;
  final bool completed;
  final bool current;
  final bool isLast;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDescription = description.trim().isNotEmpty;
    final circleColor = completed
        ? context.palette.success
        : current
        ? context.palette.mist
        : Colors.transparent;
    final borderColor = current || completed
        ? context.palette.successStrong
        : context.palette.subtle;
    return Semantics(
      button: true,
      enabled: enabled,
      toggled: completed,
      excludeSemantics: true,
      label: context.l10n.stepSemantic(
        number,
        title,
        hasDescription ? context.l10n.stepDescriptionSemantic(description) : '',
        current
            ? context.l10n.currentStepSemantic
            : completed
            ? context.l10n.completedStepSemantic
            : '',
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: hasDescription ? 78 : 68,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 74,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!isLast)
                        Positioned(
                          top: hasDescription ? 58 : 54,
                          bottom: 0,
                          child: Container(
                            width: 1.5,
                            color: completed
                                ? context.palette.success
                                : context.palette.border,
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: borderColor,
                            width: current ? 2.4 : 1.8,
                          ),
                          boxShadow: current
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: context.palette.success.withValues(
                                      alpha: 0.20,
                                    ),
                                    blurRadius: 0,
                                    spreadRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: completed
                            ? Icon(
                                Icons.check_rounded,
                                color: context.palette.onPrimary,
                                size: 28,
                              )
                            : Center(
                                child: Text(
                                  '$number',
                                  style: TextStyle(
                                    color: current
                                        ? context.palette.successStrong
                                        : context.palette.muted,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                      if (current)
                        Positioned(
                          right: 0,
                          child: Icon(
                            Icons.arrow_right_rounded,
                            color: context.palette.success,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: completed
                                ? context.palette.primary
                                : context.palette.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: context.palette.subtle,
                          ),
                        ),
                        if (hasDescription) ...[
                          const SizedBox(height: 3),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.palette.muted,
                              fontSize: 13,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordShortcut extends StatelessWidget {
  const _RecordShortcut({
    super.key,
    required this.icon,
    required this.label,
    required this.caption,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.palette.softSurface,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
        child: Column(
          children: [
            Icon(icon, color: context.palette.primary, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: context.palette.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.muted, fontSize: 9),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CompletionActionBar extends StatelessWidget {
  const _CompletionActionBar({
    required this.enabled,
    required this.submitting,
    required this.error,
    required this.onPressed,
  });

  final bool enabled;
  final bool submitting;
  final String? error;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Padding(
      padding: appSafeScrollPadding(
        context,
        const EdgeInsets.fromLTRB(20, 8, 20, 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            Text(
              error!,
              key: const Key('maintenance-completion-error'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              key: const Key('complete-maintenance'),
              onPressed: enabled ? onPressed : null,
              icon: submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.task_alt_rounded),
              label: Text(
                submitting
                    ? context.l10n.saving
                    : context.l10n.completeMaintenance,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
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
          Expanded(child: _SectionTitle(title)),
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
          context.l10n.optional,
          style: TextStyle(color: context.palette.muted),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: photos
              .map(
                (path) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(path),
                        width: 92,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 92,
                          height: 72,
                          color: context.palette.mist,
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IconButton.filled(
                        visualDensity: VisualDensity.compact,
                        onPressed: enabled ? () => onRemove(path) : null,
                        icon: const Icon(Icons.close_rounded, size: 15),
                      ),
                    ),
                  ],
                ),
              )
              .toList(growable: false),
        ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Text(label, style: TextStyle(color: context.palette.muted)),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

String? _completionCostValidator(AppLocalizations l10n, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final amount = double.tryParse(text);
  if (amount == null || !amount.isFinite || amount < 0) {
    return l10n.validationFiniteNonNegativeAmount;
  }
  return null;
}

String _money(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
