import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/maintenance_calendar.dart';
import '../models/maintenance_completion.dart';
import '../models/maintenance_task.dart';
import '../services/maintenance_execution_controller.dart';
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
        title: const Text('开始保养'),
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
            const Text(
              '执行步骤',
              style: TextStyle(
                color: Color(0xFF31584B),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            if (steps.isEmpty)
              const Text(
                '此计划没有预设步骤，可直接记录本次结果。',
                style: TextStyle(color: Color(0xFF72817A)),
              )
            else
              ...List.generate(steps.length, (index) {
                final step = steps[index];
                final completed = _completedStepIds.contains(step.id);
                return _ExecutionTimelineStep(
                  key: ValueKey('execution-step-${step.id}'),
                  number: index + 1,
                  title: step.title,
                  description: step.description,
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
            const Divider(color: Color(0xFFE2E9E2)),
            const SizedBox(height: 12),
            const Text(
              '本次记录（可选）',
              style: TextStyle(
                color: Color(0xFF31584B),
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
                    label: '日期',
                    caption: '${_completedAt.month}月${_completedAt.day}日',
                    enabled: !_submitting,
                    onTap: _editCompletionDate,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _RecordShortcut(
                    key: const Key('execution-record-cost'),
                    icon: Icons.currency_yen_rounded,
                    label: '费用',
                    caption: _cost.text.trim().isEmpty
                        ? '可留空'
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
                    label: '耗材',
                    caption: _material.text.trim().isEmpty ? '型号/名称' : '已填写',
                    enabled: !_submitting,
                    onTap: _editMaterial,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _RecordShortcut(
                    key: const Key('execution-record-note'),
                    icon: Icons.note_alt_outlined,
                    label: '备注',
                    caption: _note.text.trim().isEmpty ? '可留空' : '已填写',
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
    title: '记录本次费用',
    label: '本次费用（元）',
    helperText: '可留空，按 0 元记录',
    fieldKey: const Key('execution-cost'),
    controller: _cost,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: _completionCostValidator,
  );

  Future<void> _editMaterial() => _editTextRecord(
    title: '记录本次耗材',
    label: '耗材名称 / 型号',
    helperText: '例如：PP 棉滤芯 A1',
    fieldKey: const Key('execution-material'),
    controller: _material,
  );

  Future<void> _editNote() => _editTextRecord(
    title: '添加备注',
    label: '备注',
    helperText: '记录异常、观察结果或下次注意事项',
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
                          style: const TextStyle(
                            color: Color(0xFF263630),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭',
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
                    child: const Text('完成'),
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
                        before ? '保养前留照' : '保养后留照',
                        style: const TextStyle(
                          color: Color(0xFF263630),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _PhotoSection(
                  title: before ? '保养前照片' : '保养后照片',
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
                    before ? '执行已经开始，保养前照片已锁定。' : '步骤重新打开，完成后照片暂时不可修改。',
                    style: const TextStyle(
                      color: Color(0xFF72817A),
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
              title: const Text('拍照'),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            ListTile(
              key: const Key('execution-photo-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final result = await widget.controller.importPhoto(source);
    if (!mounted) return;
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
            ? '无法打开相机，请检查相机权限后重试。'
            : '无法读取照片，请检查照片权限后重试。',
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
    final costError = _completionCostValidator(_cost.text);
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
    } on MaintenanceCompletionException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '本次保养未能保存，请重试。');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class MaintenanceCompletionResultPage extends StatelessWidget {
  const MaintenanceCompletionResultPage({super.key, required this.result});

  final MaintenanceCompletionResult result;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('保养完成'),
      ),
      body: ListView(
        padding: appSafeScrollPadding(context, const EdgeInsets.all(24)),
        children: [
          const Icon(
            Icons.task_alt_rounded,
            size: 72,
            color: Color(0xFF3A7D70),
          ),
          const SizedBox(height: 16),
          const Text(
            '本次保养已归档',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          _ResultRow(label: '完成时间', value: _date(result.record.completedAt)),
          _ResultRow(label: '本次费用', value: '¥${_money(result.record.cost)}'),
          _ResultRow(label: '下一次计划', value: _date(result.plan.dueDate!)),
          _ResultRow(
            label: '提醒',
            value: '提前 ${result.plan.reminderLeadDays} 天',
          ),
          const SizedBox(height: 8),
          const Text(
            '继续查看这件物品的生命周期，可核对本次记录、累计费用和下一项任务。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF72817A), height: 1.45),
          ),
          if (!result.notificationScheduled) ...[
            const SizedBox(height: 16),
            Container(
              key: const Key('completion-notification-warning'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '记录和下一次日期已保存，但通知未能重新安排。可在“设置”中检查通知状态后重试。',
                style: TextStyle(color: Color(0xFF8A542E), height: 1.45),
              ),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            key: const Key('finish-maintenance-result'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('查看生命周期'),
          ),
        ],
      ),
    ),
  );
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
        color: const Color(0xFFEAF1E9),
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
                    semanticLabel: '净水器',
                  )
                : const Icon(
                    Icons.home_repair_service_outlined,
                    size: 36,
                    color: Color(0xFF31584B),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF263630),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.plan.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF31584B),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '原计划日期 ${_date(task.dueDate)}',
                  key: const Key('execution-original-status'),
                  style: const TextStyle(
                    color: Color(0xFF72817A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDCEBE1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              task.status.timingLabel,
              style: const TextStyle(
                color: Color(0xFF176B57),
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
        ? '已记录 ${photos.length} 张'
        : executionStarted
        ? '本次未记录'
        : '记录当前状态，便于完成后对比';
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: '保养前留照，可选，$status${executionStarted ? '，执行已开始，前照已锁定' : ''}',
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFFF2F4ED),
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
                      const Text(
                        '保养前留照（可选）',
                        style: TextStyle(
                          color: Color(0xFF263630),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF72817A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (editable)
                  const Icon(
                    Icons.add_a_photo_outlined,
                    color: Color(0xFF176B57),
                  )
                else if (hasPhotos)
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF72817A),
                    size: 21,
                  )
                else
                  const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF8A9992),
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
        ? '步骤已完成，记录最终状态以便对比'
        : hasAfterPhotos
        ? '步骤重新打开，完成后可继续管理照片'
        : '完成全部步骤后可添加保养后照片';
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label:
          '保养后留照，可选，${afterPhotos.isEmpty ? helper : '已记录 ${afterPhotos.length} 张'}',
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFFFFFEFA),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: const Key('execution-after-photo-entry'),
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E9E2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '保养后留照（可选）',
                        style: TextStyle(
                          color: Color(0xFF31584B),
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
                          ? const Color(0xFF176B57)
                          : const Color(0xFF8A9992),
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  helper,
                  style: const TextStyle(
                    color: Color(0xFF72817A),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: _PhotoComparisonSlot(
                        title: '保养前',
                        photos: beforePhotos,
                        emptyLabel: '未记录',
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF8EB6A7),
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: _PhotoComparisonSlot(
                        title: '保养后',
                        photos: afterPhotos,
                        emptyLabel: editable ? '点击添加' : '等待完成',
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
      color: emphasized ? const Color(0xFFEAF1E9) : const Color(0xFFF2F4ED),
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
                style: const TextStyle(
                  color: Color(0xFF263630),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                photos.isEmpty ? emptyLabel : '${photos.length} 张',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF72817A), fontSize: 10),
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
          color: const Color(0xFFEAF1E9),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: const Color(0xFF31584B), size: size * .5),
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
          color: const Color(0xFFEAF1E9),
          child: const Icon(Icons.image_outlined, color: Color(0xFF31584B)),
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
        ? const Color(0xFF3A7D70)
        : current
        ? const Color(0xFFEAF1E9)
        : Colors.transparent;
    final borderColor = current || completed
        ? const Color(0xFF176B57)
        : const Color(0xFF8A9992);
    return Semantics(
      button: true,
      enabled: enabled,
      toggled: completed,
      excludeSemantics: true,
      label:
          '步骤 $number：$title${hasDescription ? '，$description' : ''}${current
              ? '，当前步骤'
              : completed
              ? '，已完成'
              : ''}',
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
                                ? const Color(0xFF8EB6A7)
                                : const Color(0xFFCAD4CE),
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
                              ? const [
                                  BoxShadow(
                                    color: Color(0x333A7D70),
                                    blurRadius: 0,
                                    spreadRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: completed
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 28,
                              )
                            : Center(
                                child: Text(
                                  '$number',
                                  style: TextStyle(
                                    color: current
                                        ? const Color(0xFF176B57)
                                        : const Color(0xFF50615A),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                      if (current)
                        const Positioned(
                          right: 0,
                          child: Icon(
                            Icons.arrow_right_rounded,
                            color: Color(0xFF8EB6A7),
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
                                ? const Color(0xFF31584B)
                                : const Color(0xFF263630),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: const Color(0xFF8A9992),
                          ),
                        ),
                        if (hasDescription) ...[
                          const SizedBox(height: 3),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF72817A),
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
    color: const Color(0xFFF2F4ED),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF31584B), size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF263630),
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
              style: const TextStyle(color: Color(0xFF72817A), fontSize: 9),
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
              label: Text(submitting ? '正在保存…' : '完成本次保养'),
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
            label: const Text('添加'),
          ),
        ],
      ),
      if (photos.isEmpty)
        const Text('可选', style: TextStyle(color: Color(0xFF72817A)))
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
                          color: const Color(0xFFEAF1E9),
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
        Text(label, style: const TextStyle(color: Color(0xFF72817A))),
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

String? _completionCostValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final amount = double.tryParse(text);
  if (amount == null || !amount.isFinite || amount < 0) {
    return '请输入大于或等于 0 的有限金额';
  }
  return null;
}

String _money(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

String _date(DateTime value) =>
    '${value.year} 年 ${value.month} 月 ${value.day} 日';
