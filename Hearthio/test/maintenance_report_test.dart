import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/main.dart';

CareItem _reportItem({
  required String id,
  required String name,
  required String category,
  required List<MaintenancePlan> plans,
  required List<MaintenanceRecord> records,
}) => CareItem(
  id: id,
  name: name,
  category: category,
  location: '',
  brand: '',
  model: '',
  notes: '',
  photos: const [],
  plans: plans,
  records: records,
);

MaintenancePlan _reportPlan({
  required String id,
  required DateTime dueDate,
  bool enabled = true,
}) => MaintenancePlan(
  id: id,
  title: id,
  intervalDays: 30,
  dueDate: dueDate,
  enabled: enabled,
);

MaintenanceRecord _reportRecord({
  required String id,
  required DateTime completedAt,
  required double cost,
  DateTime? plannedDueDate,
}) => MaintenanceRecord(
  id: id,
  completedAt: completedAt,
  plannedDueDate: plannedDueDate,
  cost: cost,
  note: '',
);

List<CareItem> _reportFixture() => [
  _reportItem(
    id: 'air-conditioner',
    name: '客厅空调',
    category: '家电',
    plans: [
      _reportPlan(id: 'overdue', dueDate: DateTime(2026, 8, 10)),
      _reportPlan(id: 'today', dueDate: DateTime(2026, 8, 19)),
      _reportPlan(id: 'within-window', dueDate: DateTime(2026, 9, 17)),
      _reportPlan(id: 'window-end', dueDate: DateTime(2026, 9, 18)),
      _reportPlan(
        id: 'disabled',
        dueDate: DateTime(2026, 8, 1),
        enabled: false,
      ),
    ],
    records: [
      _reportRecord(
        id: 'august-on-time',
        completedAt: DateTime(2026, 8, 1),
        plannedDueDate: DateTime(2026, 8, 1),
        cost: 100,
      ),
      _reportRecord(
        id: 'august-late',
        completedAt: DateTime(2026, 8, 10),
        plannedDueDate: DateTime(2026, 8, 9),
        cost: 50,
      ),
      _reportRecord(
        id: 'july-on-time',
        completedAt: DateTime(2026, 7, 1),
        plannedDueDate: DateTime(2026, 7, 2),
        cost: 25,
      ),
      _reportRecord(
        id: 'legacy-without-due-date',
        completedAt: DateTime(2026, 1, 1),
        cost: 10,
      ),
      _reportRecord(
        id: 'outside-window',
        completedAt: DateTime(2025, 8, 31),
        plannedDueDate: DateTime(2025, 8, 31),
        cost: 999,
      ),
    ],
  ),
  _reportItem(
    id: 'purifier',
    name: '厨房净水器',
    category: '厨卫',
    plans: [_reportPlan(id: 'filter', dueDate: DateTime(2026, 8, 18))],
    records: [
      _reportRecord(
        id: 'window-start',
        completedAt: DateTime(2025, 9, 1),
        plannedDueDate: DateTime(2025, 9, 1),
        cost: 40,
      ),
    ],
  ),
];

void main() {
  test('report metrics are hand-recomputable at all date boundaries', () {
    final report = MaintenanceReportSnapshot.fromItems(
      _reportFixture(),
      now: DateTime(2026, 8, 19, 23, 59),
    );

    expect(report.currentMonthStart, DateTime(2026, 8, 1));
    expect(report.trailingYearStart, DateTime(2025, 9, 1));
    expect(report.trailingYearEnd, DateTime(2026, 9, 1));
    expect(report.nextThirtyDaysEnd, DateTime(2026, 9, 18));
    expect(report.completedThisMonth, 2);
    expect(report.currentOverdueCount, 2);
    expect(report.cumulativeOverdueDays, 10);
    expect(report.dueNextThirtyDays, 2);
    expect(report.costLastTwelveMonths, 225);
    expect(report.onTimeCompletionCount, 3);
    expect(report.eligibleCompletionCount, 4);
    expect(report.excludedCompletionCount, 1);
    expect(report.onTimeCompletionRate, .75);
    expect(report.costsByItem.map((value) => (value.label, value.amount)), [
      ('客厅空调', 185),
      ('厨房净水器', 40),
    ]);
    expect(report.costsByCategory.map((value) => (value.label, value.amount)), [
      ('家电', 185),
      ('厨卫', 40),
    ]);
  });

  test('empty report never invents a perfect completion rate', () {
    final report = MaintenanceReportSnapshot.fromItems(
      const [],
      now: DateTime(2026, 8, 19),
    );

    expect(report.totalRecordCount, 0);
    expect(report.onTimeCompletionRate, isNull);
    expect(report.costLastTwelveMonths, 0);
    expect(report.costsByItem, isEmpty);
    expect(report.costsByCategory, isEmpty);
  });

  test('planned due date remains optional and survives serialization', () {
    final record = _reportRecord(
      id: 'snapshot',
      completedAt: DateTime(2026, 8, 19),
      plannedDueDate: DateTime(2026, 8, 20),
      cost: 12.5,
    );

    final decoded = MaintenanceRecord.fromJson(record.toJson());
    final legacy = MaintenanceRecord.fromJson({
      'id': 'legacy',
      'completedAt': '2026-08-19T00:00:00.000',
      'cost': 0,
      'note': '',
    });

    expect(decoded.plannedDueDate, DateTime(2026, 8, 20));
    expect(legacy.plannedDueDate, isNull);
  });

  testWidgets('empty report explains missing data without showing 100%', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MaintenanceReportPage(items: [])),
      ),
    );

    expect(find.byKey(const Key('maintenance-report-empty')), findsOneWidget);
    expect(find.textContaining('还没有完成记录'), findsOneWidget);
    expect(find.textContaining('100%'), findsNothing);
    expect(find.byKey(const Key('maintenance-report-scope')), findsOneWidget);
  });

  testWidgets('populated report exposes metrics, range and rate definition', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaintenanceReportPage(
            items: _reportFixture(),
            now: DateTime(2026, 8, 19),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('maintenance-report-completed-month')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('maintenance-report-completed-month')),
        matching: find.text('2 项'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('maintenance-report-overdue-days')),
        matching: find.text('10 天'),
      ),
      findsOneWidget,
    );
    expect(find.text('¥225'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('maintenance-report-completion-rate')),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('75.0%'), findsOneWidget);
    expect(find.textContaining('完成日不晚于记录中的原计划到期日'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('maintenance-report-item-costs')),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('客厅空调'), findsOneWidget);
    expect(find.text('厨房净水器'), findsOneWidget);

    expect(
      find.byKey(const Key('maintenance-report-item-costs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('maintenance-report-category-costs')),
      findsNothing,
    );
    expect(find.text('物品明细'), findsOneWidget);
    expect(find.text('家用电器'), findsNothing);

    await tester.tap(
      find.byKey(const Key('maintenance-report-group-by-category')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('maintenance-report-item-costs')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('maintenance-report-category-costs')),
      findsOneWidget,
    );
    expect(find.text('类别汇总'), findsOneWidget);
    expect(find.text('家用电器'), findsOneWidget);
    expect(find.text('厨卫'), findsOneWidget);
    expect(find.text('客厅空调'), findsNothing);
    expect(find.text('厨房净水器'), findsNothing);
  });
}
