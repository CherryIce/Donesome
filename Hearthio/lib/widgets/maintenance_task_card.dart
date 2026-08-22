import 'package:flutter/material.dart';

import '../models/maintenance_status.dart';
import '../models/maintenance_task.dart';
import '../l10n/catalog_l10n.dart';
import '../l10n/l10n.dart';
import '../l10n/maintenance_l10n.dart';
import '../theme/app_theme.dart';

class MaintenanceTaskCard extends StatelessWidget {
  const MaintenanceTaskCard({
    super.key,
    required this.task,
    required this.onStart,
    required this.onDefer,
  });

  final MaintenanceTask task;
  final VoidCallback onStart;
  final VoidCallback onDefer;

  @override
  Widget build(BuildContext context) {
    final status = task.status;
    final l10n = context.l10n;
    final color = _statusColor(context, status.dueState);
    return Container(
      key: ValueKey('maintenance-task-${task.item.id}-${task.plan.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.home_repair_service_outlined, color: color),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.maintenancePlanTitleLabel(task.plan.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.palette.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  l10n.maintenanceStateLabel(status.state),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.originalDueWithTiming(
              l10n.formatDate(task.dueDate),
              l10n.maintenanceTimingLabel(status),
            ),
            key: ValueKey('maintenance-task-due-${task.id}'),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          if (status.hasActiveDeferral) ...[
            const SizedBox(height: 4),
            Text(
              l10n.deferredReminderStatus(
                l10n.formatDate(status.deferredUntil!),
                l10n.maintenanceStateLabel(status.dueState),
              ),
              key: ValueKey('maintenance-task-deferral-${task.id}'),
              style: TextStyle(color: context.palette.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: ValueKey('defer-maintenance-task-${task.id}'),
                onPressed: onDefer,
                child: Text(
                  status.hasActiveDeferral
                      ? l10n.editDeferredReminder
                      : l10n.deferReminder,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                key: ValueKey('start-maintenance-task-${task.id}'),
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(l10n.startMaintenance),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _statusColor(BuildContext context, MaintenanceTaskState state) =>
    switch (state) {
      MaintenanceTaskState.overdue => context.palette.danger,
      MaintenanceTaskState.dueToday => context.palette.warning,
      MaintenanceTaskState.dueSoon => context.palette.warning,
      MaintenanceTaskState.deferred => context.palette.deferred,
      MaintenanceTaskState.planned => context.palette.primary,
      MaintenanceTaskState.completed => context.palette.success,
      MaintenanceTaskState.disabled => context.palette.muted,
    };
