import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/maintenance_calendar.dart';
import '../models/maintenance_completion.dart';
import '../models/maintenance_task.dart';
import '../services/maintenance_execution_controller.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('开始保养')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _form,
          child: ListView(
            key: const PageStorageKey('maintenance-execution-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.item.name,
                      style: const TextStyle(
                        color: Color(0xFF263630),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.title,
                      style: const TextStyle(
                        color: Color(0xFF31584B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '原计划日期 ${_date(task.dueDate)} · ${task.status.label} · ${task.status.timingLabel}',
                      key: const Key('execution-original-status'),
                      style: const TextStyle(color: Color(0xFF72817A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _SectionTitle('执行步骤'),
              const SizedBox(height: 8),
              if (plan.checklist.isEmpty)
                const Text(
                  '此计划没有预设步骤，可直接记录本次结果。',
                  style: TextStyle(color: Color(0xFF72817A)),
                )
              else
                ...plan.checklist.map(
                  (step) => CheckboxListTile(
                    key: ValueKey('execution-step-${step.id}'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(step.title),
                    value: _completedStepIds.contains(step.id),
                    onChanged: _submitting
                        ? null
                        : (checked) => setState(() {
                            if (checked == true) {
                              _completedStepIds.add(step.id);
                            } else {
                              _completedStepIds.remove(step.id);
                            }
                          }),
                  ),
                ),
              const SizedBox(height: 18),
              const _SectionTitle('完成信息'),
              const SizedBox(height: 10),
              _DateField(
                value: _completedAt,
                firstDate: _firstCompletionDate,
                onChanged: (value) => setState(() => _completedAt = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('execution-cost'),
                controller: _cost,
                enabled: !_submitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _completionCostValidator,
                decoration: const InputDecoration(
                  labelText: '本次费用（元）',
                  helperText: '可留空，按 0 元记录',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('execution-material'),
                controller: _material,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: '耗材名称 / 型号'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('execution-note'),
                controller: _note,
                enabled: !_submitting,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: '备注'),
              ),
              const SizedBox(height: 22),
              _PhotoSection(
                title: '保养前照片',
                addKey: const Key('add-before-maintenance-photo'),
                photos: _beforePhotos,
                enabled: !_submitting,
                onAdd: () => _addPhoto(before: true),
                onRemove: (path) => _removePhoto(path, before: true),
              ),
              const SizedBox(height: 18),
              _PhotoSection(
                title: '保养后照片',
                addKey: const Key('add-after-maintenance-photo'),
                photos: _afterPhotos,
                enabled: !_submitting,
                onAdd: () => _addPhoto(before: false),
                onRemove: (path) => _removePhoto(path, before: false),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                Text(
                  _error!,
                  key: const Key('maintenance-completion-error'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('complete-maintenance'),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.task_alt_rounded),
                label: Text(_submitting ? '正在保存…' : '完成本次保养'),
              ),
            ],
          ),
        ),
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
    } else if (result.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? '无法打开相机，请检查相机权限后重试。'
                : '无法读取照片，请检查照片权限后重试。',
          ),
        ),
      );
    }
  }

  void _removePhoto(String path, {required bool before}) {
    setState(() => (before ? _beforePhotos : _afterPhotos).remove(path));
    unawaited(widget.controller.discardImportedPhoto(path));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_form.currentState?.validate() ?? false)) return;
    final allStepIds = widget.task.plan.checklist
        .map((step) => step.id)
        .toSet();
    if (!_completedStepIds.containsAll(allStepIds)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('仍有步骤未勾选'),
          content: const Text('可以继续归档，但未勾选步骤会保持未完成，不会自动补勾。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('返回检查'),
            ),
            FilledButton(
              key: const Key('confirm-incomplete-maintenance'),
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('仍然完成'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
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
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.firstDate,
    required this.onChanged,
  });

  final DateTime value;
  final DateTime firstDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    key: const Key('execution-completed-date'),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Color(0xFFE2E9E2)),
      borderRadius: BorderRadius.circular(16),
    ),
    title: const Text('实际完成日期'),
    subtitle: Text(_date(value)),
    trailing: const Icon(Icons.calendar_today_outlined),
    onTap: () async {
      final selected = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: firstDate,
        lastDate: maintenanceDateOnly(DateTime.now()),
      );
      if (selected != null) onChanged(selected);
    },
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
