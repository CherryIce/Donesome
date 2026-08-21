import 'dart:io';

import 'package:flutter/material.dart';

import '../models/care_item.dart';
import '../models/maintenance_lifecycle.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_record.dart';
import '../services/maintenance_history_controller.dart';
import 'maintenance_record_editor.dart';

const _lifecycleInk = Color(0xFF263630);
const _lifecycleMuted = Color(0xFF72817A);
const _lifecycleIndigo = Color(0xFF31584B);
const _lifecycleMist = Color(0xFFEAF1E9);
const _lifecyclePaper = Color(0xFFFFFEFA);

class MaintenanceLifecycleOverview extends StatelessWidget {
  const MaintenanceLifecycleOverview({super.key, required this.item});

  final CareItem item;

  @override
  Widget build(BuildContext context) {
    final snapshot = MaintenanceLifecycleSnapshot.fromItem(item);
    final task = snapshot.nextTask;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        key: const Key('maintenance-lifecycle-overview'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '生命周期概览',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  key: const Key('lifecycle-usage-days'),
                  label: '使用时长',
                  value: item.purchaseDate == null
                      ? '未填写购买日期'
                      : snapshot.usageDays == null
                      ? '购买日期晚于今天'
                      : '${snapshot.usageDays} 天',
                  icon: Icons.timelapse_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  key: const Key('lifecycle-completion-count'),
                  label: '累计保养',
                  value: '${snapshot.completionCount} 次',
                  icon: Icons.task_alt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  key: const Key('lifecycle-total-cost'),
                  label: '实际费用',
                  value: '¥${_money(snapshot.totalCost)}',
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  key: const Key('lifecycle-overdue-count'),
                  label: '当前逾期',
                  value: '${snapshot.overdueCount} 项',
                  icon: Icons.warning_amber_rounded,
                  alert: snapshot.overdueCount > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetricCard(
            key: const Key('lifecycle-next-task'),
            label: '下一项任务',
            value: task == null
                ? '暂无已启用且设有日期的计划'
                : '${task.plan.title} · ${_date(task.dueDate)} · ${task.status.timingLabel}',
            icon: Icons.event_available_outlined,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.alert = false,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool alert;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => Container(
    width: fullWidth ? double.infinity : null,
    constraints: const BoxConstraints(minHeight: 92),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: alert ? const Color(0xFFFFF0E5) : _lifecyclePaper,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(
        color: alert ? const Color(0xFFF1C8A9) : const Color(0xFFE3E9E2),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: alert ? const Color(0xFFB46532) : _lifecycleIndigo,
          size: 21,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: _lifecycleMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: _lifecycleInk,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class MaintenanceLifecycleTimeline extends StatefulWidget {
  const MaintenanceLifecycleTimeline({
    super.key,
    required this.item,
    required this.controller,
  });

  final CareItem item;
  final MaintenanceHistoryController controller;

  @override
  State<MaintenanceLifecycleTimeline> createState() =>
      _MaintenanceLifecycleTimelineState();
}

class _MaintenanceLifecycleTimelineState
    extends State<MaintenanceLifecycleTimeline> {
  final _busyRecordIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final entries = maintenanceTimelineForItem(widget.item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, top: 4),
      child: Column(
        key: const Key('maintenance-lifecycle-timeline'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '生命周期时间线',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 5),
          const Text(
            '仅汇总你填写的购买日期和真实维护记录，按日期倒序排列。',
            style: TextStyle(color: _lifecycleMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Container(
              key: const Key('maintenance-timeline-empty'),
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _lifecyclePaper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE3E9E2)),
              ),
              child: const Text(
                '还没有生命周期事件。填写购买日期或完成一次保养后，这里会显示可追溯记录。',
                style: TextStyle(color: _lifecycleMuted, height: 1.45),
              ),
            )
          else
            ...List.generate(entries.length, (index) {
              final entry = entries[index];
              return _TimelineNode(
                isLast: index == entries.length - 1,
                child: entry.type == MaintenanceTimelineEntryType.purchase
                    ? _PurchaseTimelineCard(date: entry.date)
                    : _RecordTimelineCard(
                        item: widget.item,
                        record: entry.record!,
                        busy: _busyRecordIds.contains(entry.record!.id),
                        onEdit: () => _edit(entry.record!),
                        onDelete: () => _delete(entry.record!),
                      ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _edit(MaintenanceRecord record) async {
    if (_busyRecordIds.contains(record.id)) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceRecordEditorPage(
          itemId: widget.item.id,
          record: record,
          plan: _planFor(widget.item, record.planId),
          controller: widget.controller,
        ),
      ),
    );
  }

  Future<void> _delete(MaintenanceRecord record) async {
    if (_busyRecordIds.contains(record.id)) return;
    final plan = _planFor(widget.item, record.planId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('删除这条维护记录？'),
        content: Text(
          plan == null
              ? '删除后无法恢复。记录中的照片也会从本机移除。'
              : '删除后无法恢复，并会按“${plan.title}”剩余记录重新计算上次完成日和下一次日期。记录照片也会从本机移除。',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('confirm-delete-maintenance-record'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyRecordIds.add(record.id));
    try {
      await widget.controller.deleteMaintenanceRecord(
        widget.item.id,
        record.id,
      );
    } on MaintenanceHistoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('维护记录未能删除，请重试。')));
      }
    } finally {
      if (mounted) setState(() => _busyRecordIds.remove(record.id));
    }
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.isLast, required this.child});

  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      if (!isLast)
        const Positioned(
          left: 13,
          top: 26,
          bottom: -12,
          child: SizedBox(
            width: 2,
            child: ColoredBox(color: Color(0xFFDCE5DC)),
          ),
        ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 20, left: 8, right: 8),
              decoration: const BoxDecoration(
                color: _lifecycleIndigo,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: child,
            ),
          ),
        ],
      ),
    ],
  );
}

class _PurchaseTimelineCard extends StatelessWidget {
  const _PurchaseTimelineCard({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('maintenance-purchase-timeline-entry'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _lifecycleMist,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '购买起点',
          style: TextStyle(color: _lifecycleInk, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(_date(date), style: const TextStyle(color: _lifecycleIndigo)),
        const SizedBox(height: 4),
        const Text(
          '来自你在物品信息中填写的购买日期。',
          style: TextStyle(color: _lifecycleMuted, height: 1.4),
        ),
      ],
    ),
  );
}

class _RecordTimelineCard extends StatelessWidget {
  const _RecordTimelineCard({
    required this.item,
    required this.record,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final CareItem item;
  final MaintenanceRecord record;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final plan = _planFor(item, record.planId);
    final checklist = [
      ...(record.stepSnapshots ??
          captureMaintenanceStepSnapshots(plan, record.completedStepIds)),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final completedKnown = checklist.where((step) => step.completed).length;
    return Container(
      key: ValueKey('maintenance-record-${record.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lifecyclePaper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E9E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.kind}${record.planId == null
                          ? ' · 未关联计划'
                          : plan == null
                          ? ' · 原计划不可用'
                          : ''}',
                      key: ValueKey('record-plan-${record.id}'),
                      style: const TextStyle(
                        color: _lifecycleInk,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _date(record.completedAt),
                      style: const TextStyle(
                        color: _lifecycleIndigo,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('edit-maintenance-record-${record.id}'),
                tooltip: '编辑记录',
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: ValueKey('delete-maintenance-record-${record.id}'),
                tooltip: '删除记录',
                onPressed: busy ? null : onDelete,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFE8EDE7)),
          _FactRow(label: '费用', value: '¥${_money(record.cost)}'),
          _FactRow(
            label: '耗材',
            value: record.materialName.isEmpty ? '未记录' : record.materialName,
          ),
          _FactRow(
            label: '备注',
            value: record.note.isEmpty ? '未记录' : record.note,
          ),
          const SizedBox(height: 8),
          if (checklist.isEmpty)
            Text(
              '步骤：未记录',
              key: ValueKey('record-steps-${record.id}'),
              style: const TextStyle(color: _lifecycleMuted),
            )
          else ...[
            Text(
              '步骤：已完成 $completedKnown / ${checklist.length}',
              key: ValueKey('record-steps-${record.id}'),
              style: const TextStyle(
                color: _lifecycleInk,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: checklist
                  .map(
                    (step) =>
                        _StepChip(title: step.title, completed: step.completed),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 12),
          if (record.beforePhotos.isEmpty && record.afterPhotos.isEmpty)
            const Text('照片：未记录', style: TextStyle(color: _lifecycleMuted))
          else ...[
            if (record.beforePhotos.isNotEmpty)
              _RecordPhotoStrip(title: '保养前', photos: record.beforePhotos),
            if (record.beforePhotos.isNotEmpty && record.afterPhotos.isNotEmpty)
              const SizedBox(height: 10),
            if (record.afterPhotos.isNotEmpty)
              _RecordPhotoStrip(title: '保养后', photos: record.afterPhotos),
          ],
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 45,
          child: Text(
            label,
            style: const TextStyle(color: _lifecycleMuted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: _lifecycleInk, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.title, required this.completed});

  final String title;
  final bool completed;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 240),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: completed ? _lifecycleMist : const Color(0xFFF2F3EF),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          completed ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 15,
          color: completed ? _lifecycleIndigo : _lifecycleMuted,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              color: completed ? _lifecycleIndigo : _lifecycleMuted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RecordPhotoStrip extends StatelessWidget {
  const _RecordPhotoStrip({required this.title, required this.photos});

  final String title;
  final List<String> photos;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$title照片 · ${photos.length} 张',
        style: const TextStyle(
          color: _lifecycleInk,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: 78,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (_, index) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(photos[index]),
              width: 92,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 92,
                height: 78,
                color: _lifecycleMist,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

MaintenancePlan? _planFor(CareItem item, String? planId) {
  if (planId == null) return null;
  for (final plan in item.plans) {
    if (plan.id == planId) return plan;
  }
  return null;
}

String _date(DateTime date) => '${date.year}年${date.month}月${date.day}日';

String _money(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
