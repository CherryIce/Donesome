import 'package:flutter/material.dart';

import '../models/care_item.dart';
import '../models/maintenance_calendar.dart';
import '../models/maintenance_report.dart';

const _reportCanvas = Color(0xFFF7F8F3);
const _reportPaper = Color(0xFFFFFEFA);
const _reportMist = Color(0xFFEAF1E9);
const _reportInk = Color(0xFF263630);
const _reportMuted = Color(0xFF72817A);
const _reportGreen = Color(0xFF31584B);
const _reportAmber = Color(0xFFE59A72);
const _reportRed = Color(0xFFB64B43);

class MaintenanceReportPage extends StatelessWidget {
  const MaintenanceReportPage({
    super.key,
    required this.items,
    this.now,
  });

  final List<CareItem> items;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final report = MaintenanceReportSnapshot.fromItems(items, now: now);
    return ColoredBox(
      color: _reportCanvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 26, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '家庭保养报告',
                  style: TextStyle(
                    color: _reportInk,
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.7,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  '只汇总真实计划、完成记录与实际费用',
                  style: TextStyle(color: _reportMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: const PageStorageKey('maintenance-report-scroll'),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [
                _ScopeCard(report: report),
                if (report.totalRecordCount == 0) ...[
                  const SizedBox(height: 12),
                  const _ReportNotice(
                    key: Key('maintenance-report-empty'),
                    icon: Icons.receipt_long_outlined,
                    text:
                        '还没有完成记录。完成一次保养后，这里会显示真实费用与完成情况；当前计划的逾期和未来任务仍照常统计。',
                  ),
                ],
                const SizedBox(height: 18),
                const _SectionTitle(
                  title: '当前任务',
                  subtitle: '按本机日历日实时计算',
                ),
                const SizedBox(height: 10),
                _MetricGrid(report: report),
                const SizedBox(height: 22),
                const _SectionTitle(
                  title: '近 12 个月',
                  subtitle: '费用与完成率使用同一自然月范围',
                ),
                const SizedBox(height: 10),
                _ReportSurface(
                  key: const Key('maintenance-report-cost'),
                  color: _reportAmber.withValues(alpha: .10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '实际维护费用',
                        style: TextStyle(color: _reportMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _money(report.costLastTwelveMonths),
                        style: const TextStyle(
                          color: _reportAmber,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_date(report.trailingYearStart)} 至 ${_date(addMaintenanceDays(report.trailingYearEnd, -1))}；只相加完成记录中的实际费用。',
                        style: const TextStyle(
                          color: _reportMuted,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      if (report.ignoredCostRecordCount > 0) ...[
                        const SizedBox(height: 5),
                        Text(
                          '${report.ignoredCostRecordCount} 条异常费用未纳入汇总。',
                          style: const TextStyle(
                            color: _reportRed,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _CompletionRateCard(report: report),
                const SizedBox(height: 22),
                const _SectionTitle(
                  title: '费用去向',
                  subtitle: '按同一近 12 个自然月范围汇总',
                ),
                const SizedBox(height: 10),
                _BreakdownSection(
                  key: const Key('maintenance-report-item-costs'),
                  title: '按物品',
                  emptyText: '暂无有金额的维护记录',
                  values: report.costsByItem,
                ),
                const SizedBox(height: 10),
                _BreakdownSection(
                  key: const Key('maintenance-report-category-costs'),
                  title: '按类别',
                  emptyText: '暂无可汇总的类别费用',
                  values: report.costsByCategory,
                ),
                if (report.recentRecords.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const _SectionTitle(
                    title: '最近维护记录',
                    subtitle: '每笔金额均可回到真实完成记录',
                  ),
                  const SizedBox(height: 10),
                  _RecentRecords(records: report.recentRecords),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({required this.report});

  final MaintenanceReportSnapshot report;

  @override
  Widget build(BuildContext context) => _ReportSurface(
    key: const Key('maintenance-report-scope'),
    color: _reportMist,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: _reportGreen, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '统计口径：本月按完成日；逾期按今天与原到期日的日历日差；未来 30 天含今天；费用与按时率统计 ${_date(report.trailingYearStart)} 至 ${_date(addMaintenanceDays(report.trailingYearEnd, -1))}。',
            style: const TextStyle(
              color: _reportInk,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.report});

  final MaintenanceReportSnapshot report;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 10.0;
      final width = (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          _MetricCard(
            key: const Key('maintenance-report-completed-month'),
            width: width,
            title: '本月已完成',
            value: '${report.completedThisMonth} 项',
            color: _reportGreen,
          ),
          _MetricCard(
            key: const Key('maintenance-report-overdue-count'),
            width: width,
            title: '当前逾期',
            value: '${report.currentOverdueCount} 项',
            color: report.currentOverdueCount == 0
                ? _reportGreen
                : _reportRed,
          ),
          _MetricCard(
            key: const Key('maintenance-report-overdue-days'),
            width: width,
            title: '累计逾期',
            value: '${report.cumulativeOverdueDays} 天',
            color: report.cumulativeOverdueDays == 0
                ? _reportGreen
                : _reportRed,
          ),
          _MetricCard(
            key: const Key('maintenance-report-upcoming-count'),
            width: width,
            title: '未来 30 天待处理',
            value: '${report.dueNextThirtyDays} 项',
            color: _reportAmber,
          ),
        ],
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.width,
    required this.title,
    required this.value,
    required this.color,
  });

  final double width;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: _ReportSurface(
      color: color.withValues(alpha: .10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            style: const TextStyle(color: _reportMuted, fontSize: 12),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CompletionRateCard extends StatelessWidget {
  const _CompletionRateCard({required this.report});

  final MaintenanceReportSnapshot report;

  @override
  Widget build(BuildContext context) {
    final rate = report.onTimeCompletionRate;
    final explanation = rate == null
        ? '暂无可复算的按时记录。旧记录或无原计划日期的记录不会被猜测为按时。'
        : '按时 ${report.onTimeCompletionCount} / 可复算 ${report.eligibleCompletionCount}。完成日不晚于记录中的原计划到期日即为按时。';
    return _ReportSurface(
      key: const Key('maintenance-report-completion-rate'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '按时完成率',
            style: TextStyle(color: _reportMuted, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            rate == null ? '—' : '${(rate * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: _reportGreen,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            explanation,
            style: const TextStyle(
              color: _reportMuted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          if (report.excludedCompletionCount > 0) ...[
            const SizedBox(height: 5),
            Text(
              '另有 ${report.excludedCompletionCount} 条记录缺少原计划日期，未纳入完成率。',
              style: const TextStyle(color: _reportMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    super.key,
    required this.title,
    required this.emptyText,
    required this.values,
  });

  final String title;
  final String emptyText;
  final List<MaintenanceCostBreakdown> values;

  @override
  Widget build(BuildContext context) => _ReportSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _reportInk,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (values.isEmpty)
          Text(
            emptyText,
            style: const TextStyle(color: _reportMuted, fontSize: 12),
          )
        else
          ...values.indexed.map(
            (entry) => Padding(
              key: ValueKey('maintenance-cost-${entry.$2.id}'),
              padding: EdgeInsets.only(top: entry.$1 == 0 ? 0 : 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.$2.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _reportInk, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _money(entry.$2.amount),
                    style: const TextStyle(
                      color: _reportGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _RecentRecords extends StatelessWidget {
  const _RecentRecords({required this.records});

  final List<MaintenanceReportRecord> records;

  @override
  Widget build(BuildContext context) => Column(
    children: records.indexed.map((entry) {
      final record = entry.$2.record;
      return Padding(
        padding: EdgeInsets.only(top: entry.$1 == 0 ? 0 : 8),
        child: _ReportSurface(
          key: ValueKey('maintenance-report-record-${record.id}'),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _reportAmber.withValues(alpha: .13),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: _reportAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.kind,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _reportInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${entry.$2.itemName} · ${_date(record.completedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _reportMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                record.cost == 0 ? '—' : _money(record.cost),
                style: const TextStyle(
                  color: _reportGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(growable: false),
  );
}

class _ReportNotice extends StatelessWidget {
  const _ReportNotice({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => _ReportSurface(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _reportGreen, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _reportMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: _reportInk,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          subtitle,
          textAlign: TextAlign.end,
          style: const TextStyle(color: _reportMuted, fontSize: 11),
        ),
      ),
    ],
  );
}

class _ReportSurface extends StatelessWidget {
  const _ReportSurface({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color ?? _reportPaper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E9E1)),
    ),
    child: child,
  );
}

String _date(DateTime value) {
  final date = maintenanceDateOnly(value);
  return '${date.year}年${date.month}月${date.day}日';
}

String _money(double amount) {
  if (!amount.isFinite || amount < 0) return '—';
  final digits = amount == amount.roundToDouble() ? 0 : 2;
  return '¥${amount.toStringAsFixed(digits)}';
}
