import 'dart:io';

import 'package:flutter/material.dart';

import '../models/care_item.dart';
import '../models/maintenance_lifecycle.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_record.dart';
import '../services/maintenance_history_controller.dart';
import '../theme/app_theme.dart';
import '../l10n/l10n.dart';
import '../l10n/maintenance_l10n.dart';
import 'app_alert.dart';
import 'app_toast.dart';
import 'maintenance_record_editor.dart';

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
          Text(
            context.l10n.lifecycleOverviewTitle,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  key: const Key('lifecycle-usage-days'),
                  label: context.l10n.lifecycleUsageDuration,
                  value: item.purchaseDate == null
                      ? context.l10n.lifecyclePurchaseDateMissing
                      : snapshot.usageDays == null
                      ? context.l10n.lifecyclePurchaseDateFuture
                      : context.l10n.lifecycleUsageDays(snapshot.usageDays!),
                  icon: Icons.timelapse_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  key: const Key('lifecycle-completion-count'),
                  label: context.l10n.lifecycleMaintenanceTotal,
                  value: context.l10n.lifecycleCompletionCount(
                    snapshot.completionCount,
                  ),
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
                  label: context.l10n.lifecycleActualCost,
                  value: '¥${_money(snapshot.totalCost)}',
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  key: const Key('lifecycle-overdue-count'),
                  label: context.l10n.lifecycleCurrentOverdue,
                  value: context.l10n.lifecycleOverdueCount(
                    snapshot.overdueCount,
                  ),
                  icon: Icons.warning_amber_rounded,
                  alert: snapshot.overdueCount > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetricCard(
            key: const Key('lifecycle-next-task'),
            label: context.l10n.lifecycleNextTask,
            value: task == null
                ? context.l10n.lifecycleNoNextTask
                : context.l10n.lifecycleNextTaskSummary(
                    context.l10n.maintenancePlanTitleLabel(task.plan.title),
                    _date(context, task.dueDate),
                    context.l10n.maintenanceTimingLabel(task.status),
                  ),
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
      color: alert ? context.palette.warningSurface : context.palette.paper,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(
        color: alert
            ? context.palette.warning.withValues(alpha: 0.55)
            : context.palette.border,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: alert
              ? context.palette.warningStrong
              : context.palette.primary,
          size: 21,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: context.palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: context.palette.ink,
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
          Text(
            context.l10n.lifecycleTimelineTitle,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 5),
          Text(
            context.l10n.lifecycleTimelineSubtitle,
            style: TextStyle(color: context.palette.muted, height: 1.4),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Container(
              key: const Key('maintenance-timeline-empty'),
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.palette.paper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.palette.border),
              ),
              child: Text(
                context.l10n.lifecycleTimelineEmpty,
                style: TextStyle(color: context.palette.muted, height: 1.45),
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
    final confirmed = await showAppAlert<bool>(
      context,
      title: context.l10n.deleteRecordTitle,
      message: plan == null
          ? context.l10n.deleteRecordMessageNoPlan
          : context.l10n.deleteRecordMessageWithPlan(
              context.l10n.maintenancePlanTitleLabel(plan.title),
            ),
      actions: [
        AppAlertAction(label: context.l10n.commonCancel, result: false),
        AppAlertAction(
          label: context.l10n.confirmDelete,
          result: true,
          key: Key('confirm-delete-maintenance-record'),
          tone: AppAlertActionTone.destructive,
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyRecordIds.add(record.id));
    try {
      await widget.controller.deleteMaintenanceRecord(
        widget.item.id,
        record.id,
      );
    } on MaintenanceHistoryException {
      if (mounted) {
        AppToast.show(
          context,
          context.l10n.deleteRecordFailed,
          style: AppToastStyle.error,
        );
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          context.l10n.deleteRecordFailed,
          style: AppToastStyle.error,
        );
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
        Positioned(
          left: 13,
          top: 26,
          bottom: -12,
          child: SizedBox(
            width: 2,
            child: ColoredBox(color: context.palette.border),
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
              decoration: BoxDecoration(
                color: context.palette.primary,
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
      color: context.palette.mist,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.purchaseStartingPoint,
          style: TextStyle(
            color: context.palette.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _date(context, date),
          style: TextStyle(color: context.palette.primary),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.purchaseStartingPointDescription,
          style: TextStyle(color: context.palette.muted, height: 1.4),
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
    final planState = record.planId == null
        ? context.l10n.recordPlanUnlinked
        : plan == null
        ? context.l10n.recordPlanUnavailable
        : null;
    return Container(
      key: ValueKey('maintenance-record-${record.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
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
                      planState == null
                          ? context.l10n.maintenancePlanTitleLabel(record.kind)
                          : context.l10n.recordTitleWithPlanState(
                              context.l10n.maintenancePlanTitleLabel(
                                record.kind,
                              ),
                              planState,
                            ),
                      key: ValueKey('record-plan-${record.id}'),
                      style: TextStyle(
                        color: context.palette.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _date(context, record.completedAt),
                      style: TextStyle(
                        color: context.palette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('edit-maintenance-record-${record.id}'),
                tooltip: context.l10n.editRecordTooltip,
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: ValueKey('delete-maintenance-record-${record.id}'),
                tooltip: context.l10n.deleteRecordTooltip,
                onPressed: busy ? null : onDelete,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.delete_outline, color: context.palette.danger),
              ),
            ],
          ),
          Divider(height: 20, color: context.palette.divider),
          _FactRow(
            label: context.l10n.recordExpense,
            value: '¥${_money(record.cost)}',
          ),
          _FactRow(
            label: context.l10n.recordMaterial,
            value: record.materialName.isEmpty
                ? context.l10n.notRecorded
                : record.materialName,
          ),
          _FactRow(
            label: context.l10n.recordNotes,
            value: record.note.isEmpty ? context.l10n.notRecorded : record.note,
          ),
          const SizedBox(height: 8),
          if (checklist.isEmpty)
            Text(
              context.l10n.recordStepsMissing,
              key: ValueKey('record-steps-${record.id}'),
              style: TextStyle(color: context.palette.muted),
            )
          else ...[
            Text(
              context.l10n.recordStepsProgress(
                completedKnown,
                checklist.length,
              ),
              key: ValueKey('record-steps-${record.id}'),
              style: TextStyle(
                color: context.palette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: checklist
                  .map(
                    (step) => _StepChip(
                      title: context.l10n.maintenanceStepTitleLabel(step.title),
                      completed: step.completed,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 12),
          if (record.beforePhotos.isEmpty && record.afterPhotos.isEmpty)
            Text(
              context.l10n.recordPhotosMissing,
              style: TextStyle(color: context.palette.muted),
            )
          else ...[
            if (record.beforePhotos.isNotEmpty)
              _RecordPhotoStrip(
                title: context.l10n.beforeLabel,
                photos: record.beforePhotos,
              ),
            if (record.beforePhotos.isNotEmpty && record.afterPhotos.isNotEmpty)
              const SizedBox(height: 10),
            if (record.afterPhotos.isNotEmpty)
              _RecordPhotoStrip(
                title: context.l10n.afterLabel,
                photos: record.afterPhotos,
              ),
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
            style: TextStyle(color: context.palette.muted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: context.palette.ink, height: 1.4),
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
      color: completed ? context.palette.mist : context.palette.softSurface,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          completed ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 15,
          color: completed ? context.palette.primary : context.palette.muted,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              color: completed
                  ? context.palette.primary
                  : context.palette.muted,
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
        context.l10n.recordPhotoGroup(title, photos.length),
        style: TextStyle(
          color: context.palette.ink,
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
                color: context.palette.mist,
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

String _date(BuildContext context, DateTime date) =>
    context.l10n.dateYmd(date.year, date.month, date.day);

String _money(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
