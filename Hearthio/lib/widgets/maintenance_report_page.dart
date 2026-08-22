import 'package:flutter/material.dart';

import '../models/care_item.dart';
import '../models/maintenance_calendar.dart';
import '../models/maintenance_report.dart';
import '../l10n/catalog_l10n.dart';
import '../l10n/l10n.dart';
import '../l10n/maintenance_l10n.dart';
import '../theme/app_theme.dart';

enum MaintenanceReportScope { trailingTwelveMonths, currentYear }

enum _MaintenanceCostGrouping { item, category }

class MaintenanceReportPage extends StatefulWidget {
  const MaintenanceReportPage({
    super.key,
    required this.items,
    this.now,
    this.initialScope = MaintenanceReportScope.trailingTwelveMonths,
    this.navigationVersion = 0,
    this.onOpenItem,
  });

  final List<CareItem> items;
  final DateTime? now;
  final MaintenanceReportScope initialScope;
  final int navigationVersion;
  final ValueChanged<String>? onOpenItem;

  @override
  State<MaintenanceReportPage> createState() => _MaintenanceReportPageState();
}

class _MaintenanceReportPageState extends State<MaintenanceReportPage> {
  late MaintenanceReportScope scope = widget.initialScope;
  _MaintenanceCostGrouping costGrouping = _MaintenanceCostGrouping.item;

  @override
  void didUpdateWidget(covariant MaintenanceReportPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationVersion != widget.navigationVersion) {
      scope = widget.initialScope;
      costGrouping = _MaintenanceCostGrouping.item;
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = MaintenanceReportSnapshot.fromItems(
      widget.items,
      now: widget.now,
    );
    final isCurrentYear = scope == MaintenanceReportScope.currentYear;
    final rangeStart = isCurrentYear
        ? report.currentYearStart
        : report.trailingYearStart;
    final rangeEnd = isCurrentYear
        ? report.currentYearEnd
        : report.trailingYearEnd;
    final scopedCost = isCurrentYear
        ? report.costCurrentYear
        : report.costLastTwelveMonths;
    final scopedItemCosts = isCurrentYear
        ? report.currentYearCostsByItem
        : report.costsByItem;
    final scopedCategoryCosts = isCurrentYear
        ? report.currentYearCostsByCategory
        : report.costsByCategory;
    final ignoredCostCount = isCurrentYear
        ? report.ignoredCurrentYearCostRecordCount
        : report.ignoredCostRecordCount;
    final scopedRecords = report.recentRecords
        .where((entry) {
          final completedAt = maintenanceDateOnly(entry.record.completedAt);
          return !completedAt.isBefore(rangeStart) &&
              completedAt.isBefore(rangeEnd);
        })
        .toList(growable: false);
    return ColoredBox(
      color: context.palette.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.reportPageTitle,
                  style: TextStyle(
                    color: context.palette.ink,
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.7,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  context.l10n.reportPageSubtitle,
                  style: TextStyle(color: context.palette.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: const PageStorageKey('maintenance-report-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [
                _ScopeSelector(
                  scope: scope,
                  onChanged: (value) => setState(() => scope = value),
                ),
                const SizedBox(height: 10),
                _ScopeCard(report: report, scope: scope),
                if (report.totalRecordCount == 0) ...[
                  const SizedBox(height: 12),
                  _ReportNotice(
                    key: const Key('maintenance-report-empty'),
                    icon: Icons.receipt_long_outlined,
                    text: context.l10n.reportEmptyNotice,
                  ),
                ],
                const SizedBox(height: 18),
                _SectionTitle(
                  title: context.l10n.reportCurrentTasks,
                  subtitle: context.l10n.reportCurrentTasksSubtitle,
                ),
                const SizedBox(height: 10),
                _MetricGrid(report: report),
                const SizedBox(height: 22),
                _SectionTitle(
                  title: isCurrentYear
                      ? context.l10n.reportCurrentYearMaintenance
                      : context.l10n.reportTrailingYearMaintenance,
                  subtitle: isCurrentYear
                      ? context.l10n.reportCurrentYearCostSubtitle
                      : context.l10n.reportTrailingYearCostSubtitle,
                ),
                const SizedBox(height: 10),
                _ReportSurface(
                  key: const Key('maintenance-report-cost'),
                  color: context.palette.accent.withValues(alpha: .10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.reportActualMaintenanceCost,
                        style: TextStyle(
                          color: context.palette.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _money(scopedCost),
                        style: TextStyle(
                          color: context.palette.accent,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.reportCostRangeDescription(
                          _date(context, rangeStart),
                          _date(context, addMaintenanceDays(rangeEnd, -1)),
                        ),
                        style: TextStyle(
                          color: context.palette.muted,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      if (ignoredCostCount > 0) ...[
                        const SizedBox(height: 5),
                        Text(
                          context.l10n.reportIgnoredCostCount(ignoredCostCount),
                          style: TextStyle(
                            color: context.palette.danger,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isCurrentYear) ...[
                  const SizedBox(height: 10),
                  _CompletionRateCard(report: report),
                ],
                const SizedBox(height: 22),
                _SectionTitle(
                  title: context.l10n.reportCostBreakdown,
                  subtitle: context.l10n.reportCostBreakdownSubtitle,
                ),
                const SizedBox(height: 10),
                _CostGroupingSelector(
                  grouping: costGrouping,
                  onChanged: (value) => setState(() => costGrouping = value),
                ),
                const SizedBox(height: 10),
                _BreakdownSection(
                  key: ValueKey(
                    costGrouping == _MaintenanceCostGrouping.item
                        ? 'maintenance-report-item-costs'
                        : 'maintenance-report-category-costs',
                  ),
                  title: costGrouping == _MaintenanceCostGrouping.item
                      ? context.l10n.reportItemBreakdown
                      : context.l10n.reportCategoryBreakdown,
                  emptyText: costGrouping == _MaintenanceCostGrouping.item
                      ? context.l10n.reportNoItemCosts
                      : context.l10n.reportNoCategoryCosts,
                  values: costGrouping == _MaintenanceCostGrouping.item
                      ? scopedItemCosts
                      : scopedCategoryCosts,
                  localizeCategories:
                      costGrouping == _MaintenanceCostGrouping.category,
                  onOpen: costGrouping == _MaintenanceCostGrouping.item
                      ? widget.onOpenItem
                      : null,
                ),
                if (scopedRecords.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionTitle(
                    title: context.l10n.reportRecentRecords,
                    subtitle: context.l10n.reportRecentRecordsSubtitle,
                  ),
                  const SizedBox(height: 10),
                  _RecentRecords(
                    records: scopedRecords,
                    onOpenItem: widget.onOpenItem,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CostGroupingSelector extends StatelessWidget {
  const _CostGroupingSelector({
    required this.grouping,
    required this.onChanged,
  });

  final _MaintenanceCostGrouping grouping;
  final ValueChanged<_MaintenanceCostGrouping> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.l10n.reportGroupingSemantic,
    child: Row(
      children: [
        Expanded(
          child: _ScopeButton(
            key: const Key('maintenance-report-group-by-item'),
            label: context.l10n.reportGroupByItem,
            selected: grouping == _MaintenanceCostGrouping.item,
            onTap: () => onChanged(_MaintenanceCostGrouping.item),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ScopeButton(
            key: const Key('maintenance-report-group-by-category'),
            label: context.l10n.reportGroupByCategory,
            selected: grouping == _MaintenanceCostGrouping.category,
            onTap: () => onChanged(_MaintenanceCostGrouping.category),
          ),
        ),
      ],
    ),
  );
}

class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({required this.scope, required this.onChanged});

  final MaintenanceReportScope scope;
  final ValueChanged<MaintenanceReportScope> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ScopeButton(
          key: const Key('maintenance-report-scope-current-year'),
          label: context.l10n.reportScopeCurrentYear,
          selected: scope == MaintenanceReportScope.currentYear,
          onTap: () => onChanged(MaintenanceReportScope.currentYear),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ScopeButton(
          key: const Key('maintenance-report-scope-trailing-year'),
          label: context.l10n.reportScopeTrailingYear,
          selected: scope == MaintenanceReportScope.trailingTwelveMonths,
          onTap: () => onChanged(MaintenanceReportScope.trailingTwelveMonths),
        ),
      ),
    ],
  );
}

class _ScopeButton extends StatelessWidget {
  const _ScopeButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? context.palette.primary : context.palette.paper,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? context.palette.primary
                  : context.palette.border,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? context.palette.onPrimary : context.palette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({required this.report, required this.scope});

  final MaintenanceReportSnapshot report;
  final MaintenanceReportScope scope;

  @override
  Widget build(BuildContext context) => _ReportSurface(
    key: const Key('maintenance-report-scope'),
    color: context.palette.mist,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: context.palette.primary,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            scope == MaintenanceReportScope.currentYear
                ? context.l10n.reportCurrentYearMethodology(
                    _date(context, report.currentYearStart),
                    _date(
                      context,
                      addMaintenanceDays(report.currentYearEnd, -1),
                    ),
                  )
                : context.l10n.reportTrailingYearMethodology(
                    _date(context, report.trailingYearStart),
                    _date(
                      context,
                      addMaintenanceDays(report.trailingYearEnd, -1),
                    ),
                  ),
            style: TextStyle(
              color: context.palette.ink,
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
            title: context.l10n.reportCompletedThisMonth,
            value: context.l10n.reportItemCount(report.completedThisMonth),
            color: context.palette.primary,
          ),
          _MetricCard(
            key: const Key('maintenance-report-overdue-count'),
            width: width,
            title: context.l10n.reportCurrentOverdue,
            value: context.l10n.reportItemCount(report.currentOverdueCount),
            color: report.currentOverdueCount == 0
                ? context.palette.primary
                : context.palette.danger,
          ),
          _MetricCard(
            key: const Key('maintenance-report-overdue-days'),
            width: width,
            title: context.l10n.reportCumulativeOverdue,
            value: context.l10n.reportDayCount(report.cumulativeOverdueDays),
            color: report.cumulativeOverdueDays == 0
                ? context.palette.primary
                : context.palette.danger,
          ),
          _MetricCard(
            key: const Key('maintenance-report-upcoming-count'),
            width: width,
            title: context.l10n.reportDueNextThirtyDays,
            value: context.l10n.reportItemCount(report.dueNextThirtyDays),
            color: context.palette.accent,
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
            style: TextStyle(color: context.palette.muted, fontSize: 12),
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
        ? context.l10n.reportNoEligibleOnTimeRecords
        : context.l10n.reportOnTimeExplanation(
            report.onTimeCompletionCount,
            report.eligibleCompletionCount,
          );
    return _ReportSurface(
      key: const Key('maintenance-report-completion-rate'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.reportOnTimeRate,
            style: TextStyle(color: context.palette.muted, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            rate == null ? '—' : '${(rate * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: context.palette.primary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            explanation,
            style: TextStyle(
              color: context.palette.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          if (report.excludedCompletionCount > 0) ...[
            const SizedBox(height: 5),
            Text(
              context.l10n.reportExcludedCompletionCount(
                report.excludedCompletionCount,
              ),
              style: TextStyle(color: context.palette.muted, fontSize: 12),
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
    this.localizeCategories = false,
    this.onOpen,
  });

  final String title;
  final String emptyText;
  final List<MaintenanceCostBreakdown> values;
  final bool localizeCategories;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) => _ReportSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.palette.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (values.isEmpty)
          Text(
            emptyText,
            style: TextStyle(color: context.palette.muted, fontSize: 12),
          )
        else
          ...values.indexed.map((entry) {
            final row = Padding(
              padding: EdgeInsets.only(top: entry.$1 == 0 ? 0 : 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      localizeCategories
                          ? context.l10n.itemCategoryLabel(entry.$2.label)
                          : context.l10n.reportItemLabel(entry.$2.label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.palette.ink,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _money(entry.$2.amount),
                    style: TextStyle(
                      color: context.palette.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (onOpen != null) ...[
                    const SizedBox(width: 7),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.palette.muted,
                      size: 18,
                    ),
                  ],
                ],
              ),
            );
            return Material(
              key: ValueKey('maintenance-cost-${entry.$2.id}'),
              color: Colors.transparent,
              child: onOpen == null
                  ? row
                  : InkWell(
                      onTap: () => onOpen!(entry.$2.id),
                      borderRadius: BorderRadius.circular(10),
                      child: row,
                    ),
            );
          }),
      ],
    ),
  );
}

class _RecentRecords extends StatelessWidget {
  const _RecentRecords({required this.records, this.onOpenItem});

  final List<MaintenanceReportRecord> records;
  final ValueChanged<String>? onOpenItem;

  @override
  Widget build(BuildContext context) => Column(
    children: records.indexed
        .map((entry) {
          final record = entry.$2.record;
          return Padding(
            padding: EdgeInsets.only(top: entry.$1 == 0 ? 0 : 8),
            child: Material(
              key: ValueKey('maintenance-report-record-${record.id}'),
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenItem == null
                    ? null
                    : () => onOpenItem!(entry.$2.itemId),
                borderRadius: BorderRadius.circular(20),
                child: _ReportSurface(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.palette.accent.withValues(alpha: .13),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: context.palette.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.maintenancePlanTitleLabel(
                                record.kind,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.palette.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              context.l10n.reportRecordSubtitle(
                                context.l10n.itemNameLabel(
                                  id: entry.$2.itemId,
                                  isSample: entry.$2.itemId == 'sample-filter',
                                  name: entry.$2.itemName,
                                ),
                                _date(context, record.completedAt),
                              ),
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
                      const SizedBox(width: 10),
                      Text(
                        record.cost == 0 ? '—' : _money(record.cost),
                        style: TextStyle(
                          color: context.palette.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (onOpenItem != null)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.palette.muted,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        })
        .toList(growable: false),
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
        Icon(icon, color: context.palette.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: context.palette.muted,
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
          style: TextStyle(
            color: context.palette.ink,
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
          style: TextStyle(color: context.palette.muted, fontSize: 11),
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
      color: color ?? context.palette.paper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.palette.border),
    ),
    child: child,
  );
}

String _date(BuildContext context, DateTime value) {
  final date = maintenanceDateOnly(value);
  return context.l10n.dateYmd(date.year, date.month, date.day);
}

String _money(double amount) {
  if (!amount.isFinite || amount < 0) return '—';
  final digits = amount == amount.roundToDouble() ? 0 : 2;
  return '¥${amount.toStringAsFixed(digits)}';
}
