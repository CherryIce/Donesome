import 'package:flutter/material.dart';

import '../models/maintenance_status.dart';
import '../models/maintenance_task.dart';

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
    final color = _statusColor(status.dueState);
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
                      task.item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF263630),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.plan.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF72817A)),
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
                  status.label,
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
            '原到期日 ${_date(task.dueDate)} · ${status.timingLabel}',
            key: ValueKey('maintenance-task-due-${task.id}'),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          if (status.hasActiveDeferral) ...[
            const SizedBox(height: 4),
            Text(
              '稍后提醒 ${_date(status.deferredUntil!)} · 原状态 ${status.dueStateLabel}',
              key: ValueKey('maintenance-task-deferral-${task.id}'),
              style: const TextStyle(color: Color(0xFF72817A), fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: ValueKey('defer-maintenance-task-${task.id}'),
                onPressed: onDefer,
                child: Text(status.hasActiveDeferral ? '修改稍后提醒' : '稍后提醒'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                key: ValueKey('start-maintenance-task-${task.id}'),
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('开始保养'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _statusColor(MaintenanceTaskState state) => switch (state) {
  MaintenanceTaskState.overdue => const Color(0xFFB64B43),
  MaintenanceTaskState.dueToday => const Color(0xFFC36F2D),
  MaintenanceTaskState.dueSoon => const Color(0xFF9B7328),
  MaintenanceTaskState.deferred => const Color(0xFF725E91),
  MaintenanceTaskState.planned => const Color(0xFF31584B),
  MaintenanceTaskState.completed => const Color(0xFF3A7D70),
  MaintenanceTaskState.disabled => const Color(0xFF72817A),
};

String _date(DateTime value) => '${value.year}年${value.month}月${value.day}日';
