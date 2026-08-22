import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/maintenance_calendar.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_record.dart';
import '../services/maintenance_history_controller.dart';
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
        title: const Text('编辑维护记录'),
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
                color: const Color(0xFFEAF1E9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '所属计划',
                    style: TextStyle(color: Color(0xFF72817A)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.record.kind}${widget.plan == null && widget.record.planId != null ? '（原计划不可用）' : ''}',
                    key: const Key('record-editor-plan'),
                    style: const TextStyle(
                      color: Color(0xFF263630),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '记录与原计划的关联不会在编辑时改变。',
                    style: TextStyle(color: Color(0xFF72817A), fontSize: 12),
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
              validator: _costValidator,
              decoration: const InputDecoration(
                labelText: '本次费用（元）',
                helperText: '可留空，按 0 元记录',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('record-editor-material'),
              controller: _material,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: '耗材名称 / 型号'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('record-editor-note'),
              controller: _note,
              enabled: !_saving,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(labelText: '备注'),
            ),
            const SizedBox(height: 20),
            const Text(
              '执行步骤',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            if (checklist.isEmpty)
              Text(
                _completedStepIds.isEmpty
                    ? '这条记录没有步骤数据。'
                    : '已保留 ${_completedStepIds.length} 个历史步骤标识；原步骤内容不可用。',
                style: const TextStyle(color: Color(0xFF72817A)),
              )
            else
              ...checklist.map(
                (step) => CheckboxListTile(
                  key: ValueKey('record-editor-step-${step.id}'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _completedStepIds.contains(step.id),
                  title: Text(step.title),
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
              title: '保养前照片',
              addKey: const Key('record-editor-add-before-photo'),
              photos: _beforePhotos,
              enabled: !_saving,
              onAdd: () => _addPhoto(before: true),
              onRemove: (path) => _removePhoto(path, before: true),
            ),
            const SizedBox(height: 18),
            _EditableRecordPhotos(
              title: '保养后照片',
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
              label: Text(_saving ? '正在保存…' : '保存记录'),
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
              title: const Text('拍照'),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            ListTile(
              key: const Key('record-editor-photo-gallery'),
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
            ? '无法打开相机，请检查相机权限后重试。'
            : '无法读取照片，请检查照片权限后重试。',
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
    } on MaintenanceHistoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '维护记录未能保存，请重试。');
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
      side: const BorderSide(color: Color(0xFFE2E9E2)),
      borderRadius: BorderRadius.circular(16),
    ),
    title: const Text('实际完成日期'),
    subtitle: Text(_date(value)),
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
            label: const Text('添加'),
          ),
        ],
      ),
      if (photos.isEmpty)
        const Text('未添加照片', style: TextStyle(color: Color(0xFF72817A)))
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
                        color: const Color(0xFFEAF1E9),
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 3,
                    right: 3,
                    child: IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      tooltip: '移除照片',
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

String? _costValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final number = double.tryParse(text);
  if (number == null || !number.isFinite || number < 0) {
    return '请输入大于或等于 0 的金额';
  }
  return null;
}

String _date(DateTime date) => '${date.year}年${date.month}月${date.day}日';

String _money(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
