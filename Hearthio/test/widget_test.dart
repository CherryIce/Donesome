import 'dart:convert';
import 'dart:async';

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/main.dart';
import 'package:hearthio/privacy_policy_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeExecutionController implements MaintenanceExecutionController {
  _FakeExecutionController({
    required this.task,
    this.notificationScheduled = false,
    this.completionError,
    this.completionGate,
    List<String> importedPaths = const [],
  }) : importedPaths = [...importedPaths];

  final MaintenanceTask task;
  final bool notificationScheduled;
  final Object? completionError;
  final Completer<void>? completionGate;
  final List<String> importedPaths;
  final List<String> discardedPaths = [];
  MaintenanceCompletionDraft? lastDraft;
  int completeCalls = 0;

  @override
  Future<MaintenanceCompletionResult> completeMaintenance(
    MaintenanceCompletionDraft draft,
  ) async {
    completeCalls++;
    lastDraft = draft;
    if (completionGate != null) await completionGate!.future;
    if (completionError != null) throw completionError!;
    final completedPlan = task.plan.completedAt(draft.completedAt);
    final record = MaintenanceRecord(
      id: draft.recordId,
      planId: task.plan.id,
      completedAt: draft.completedAt,
      kind: task.plan.title,
      cost: draft.cost,
      materialName: draft.materialName,
      note: draft.note,
      completedStepIds: draft.completedStepIds,
      beforePhotos: draft.beforePhotos,
      afterPhotos: draft.afterPhotos,
    );
    final completedItem = task.item.copyWith(
      plans: [
        for (final plan in task.item.plans)
          if (plan.id == completedPlan.id) completedPlan else plan,
      ],
      records: [...task.item.records, record],
    );
    return MaintenanceCompletionResult(
      item: completedItem,
      plan: completedPlan,
      record: record,
      notificationScheduled: notificationScheduled,
    );
  }

  @override
  Future<void> discardImportedPhoto(String path) async {
    discardedPaths.add(path);
  }

  @override
  Future<PhotoImportResult> importPhoto(ImageSource source) async =>
      importedPaths.isEmpty
      ? const PhotoImportResult.cancelled()
      : PhotoImportResult.success(importedPaths.removeAt(0));
}

MaintenanceTask _executionTask() {
  final today = maintenanceDateOnly(DateTime.now());
  final item = CareItem(
    id: 'purifier',
    name: '厨房净水器',
    category: '家电',
    location: '厨房',
    brand: '',
    model: '',
    notes: '',
    photos: const [],
    plans: [
      MaintenancePlan(
        id: 'filter',
        title: '更换滤芯',
        intervalDays: 180,
        reminderLeadDays: 3,
        dueDate: addMaintenanceDays(today, -2),
        checklist: const [
          MaintenanceStep(id: 'water-off', title: '关闭水源', sortOrder: 0),
          MaintenanceStep(id: 'flush', title: '冲洗', sortOrder: 1),
        ],
      ),
    ],
  );
  final plan = item.plans.single;
  return MaintenanceTask(
    item: item,
    plan: plan,
    status: MaintenancePlanStatus.evaluate(plan),
  );
}

void main() {
  test('item archive round-trip preserves maintenance records and photos', () {
    final item = CareItem(
      id: 'item-1',
      name: 'Air purifier',
      category: '家电',
      location: 'Living room',
      brand: 'Test',
      model: 'A1',
      notes: 'Filter checked',
      photos: ['/local/photo.jpg'],
      lastCareDate: DateTime(2026, 1, 1),
      intervalDays: 90,
      records: [
        MaintenanceRecord(
          date: DateTime(2026, 1, 1),
          kind: 'Cleaning',
          cost: 20,
          note: 'Done',
        ),
      ],
    );
    final restored = CareItem.fromJson(item.toJson());
    expect(restored.nextCareDate, DateTime(2026, 4, 1));
    expect(restored.photos.single, '/local/photo.jpg');
    expect(restored.records.single.cost, 20);
    expect(restored.records.single.kind, 'Cleaning');
  });

  test('missing maintenance interval does not produce a reminder date', () {
    final item = CareItem(
      id: 'item-2',
      name: 'Kettle',
      category: '家电',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: [],
      lastCareDate: DateTime(2026, 1, 1),
    );
    expect(item.nextCareDate, isNull);
  });

  test('editing can clear optional asset values', () {
    final item = CareItem(
      id: 'item-3',
      name: 'Washer',
      category: '家电',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: [],
      purchasePrice: 3000,
      currentValue: 1800,
    );

    final cleared = item.copyWith(
      clearPurchasePrice: true,
      clearCurrentValue: true,
    );
    expect(cleared.purchasePrice, isNull);
    expect(cleared.currentValue, isNull);
  });

  test('notification status distinguishes first request from denial', () {
    expect(
      notificationAccessFrom(
        notificationsEnabled: false,
        permissionPrompted: false,
      ),
      NotificationAccess.notDetermined,
    );
    expect(
      notificationAccessFrom(
        notificationsEnabled: false,
        permissionPrompted: true,
      ),
      NotificationAccess.denied,
    );
    expect(
      notificationAccessFrom(
        notificationsEnabled: true,
        permissionPrompted: true,
      ),
      NotificationAccess.enabled,
    );
  });

  test('first load seeds one explicitly marked purifier example', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CareStore();

    await store.load();

    final today = maintenanceDateOnly(DateTime.now());
    final plan = store.items.single.plans.single;
    expect(store.items, hasLength(1));
    expect(store.items.single.isSample, isTrue);
    expect(store.items.single.name, '示例 · 厨房净水器');
    expect(plan.id, 'sample-filter-plan');
    expect(plan.title, '更换滤芯');
    expect(plan.dueDate, today);
    expect(plan.checklist.map((step) => step.title), [
      '核对型号',
      '关闭水源',
      '更换',
      '冲洗',
    ]);
    expect(CareItem.fromJson(store.items.single.toJson()).isSample, isTrue);
  });

  test(
    'unused marked legacy sample upgrades without touching user items',
    () async {
      final oldSample = CareItem(
        id: 'sample-filter',
        name: '示例 · 厨房净水器',
        category: '滤芯与耗材',
        location: '厨房',
        brand: '',
        model: '',
        notes: '',
        photos: const [],
        lastCareDate: addMaintenanceDays(DateTime.now(), -150),
        intervalDays: 180,
        isSample: true,
      );
      final userItem = CareItem(
        id: 'user-item',
        name: '我的洗衣机',
        category: '家电',
        location: '',
        brand: '',
        model: '',
        notes: '',
        photos: const [],
      );
      SharedPreferences.setMockInitialValues({
        CareRepository.storageKey: CareDataEnvelope(
          items: [oldSample, userItem],
        ).encode(),
      });
      final store = CareStore();

      await store.load();

      final sample = store.items.firstWhere((item) => item.isSample);
      expect(sample.plans.single.id, 'sample-filter-plan');
      expect(sample.plans.single.title, '更换滤芯');
      expect(store.items.map((item) => item.id), contains('user-item'));
    },
  );

  test('sample history is preserved instead of being silently reset', () async {
    final completedSample = CareItem(
      id: 'sample-filter',
      name: '示例 · 厨房净水器',
      category: '滤芯与耗材',
      location: '厨房',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      lastCareDate: DateTime(2026, 1, 1),
      intervalDays: 180,
      records: [
        MaintenanceRecord(
          id: 'kept-record',
          planId: 'legacy-plan-sample-filter',
          completedAt: DateTime(2026, 1, 1),
          cost: 20,
          note: '',
        ),
      ],
      isSample: true,
    );
    SharedPreferences.setMockInitialValues({
      CareRepository.storageKey: CareDataEnvelope(
        items: [completedSample],
      ).encode(),
    });
    final store = CareStore();

    await store.load();

    expect(store.items.single.records.single.id, 'kept-record');
    expect(store.items.single.plans.single.id, 'legacy-plan-sample-filter');
  });

  test('legacy two-example data migrates to one marked purifier', () async {
    Map<String, Object> item(String id, String name) => {
      'id': id,
      'name': name,
      'category': '家电',
      'location': '',
      'brand': '',
      'model': '',
      'notes': '',
      'photos': <String>[],
    };
    SharedPreferences.setMockInitialValues({
      'care_items': jsonEncode([
        item('sample-filter', '厨房净水器'),
        item('sample-ac', '客厅空调'),
        item('user-item', '我的洗衣机'),
      ]),
    });
    final store = CareStore();

    await store.load();

    expect(store.items.where((entry) => entry.isSample), hasLength(1));
    expect(store.items.map((entry) => entry.id), isNot(contains('sample-ac')));
    expect(store.items.map((entry) => entry.id), contains('user-item'));
  });

  test('resetting example data preserves user-created items', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CareStore();
    await store.load();
    store.items.add(
      CareItem(
        id: 'user-item',
        name: '我的洗衣机',
        category: '家电',
        location: '',
        brand: '',
        model: '',
        notes: '',
        photos: [],
      ),
    );

    await store.resetExampleData();
    await store.deleteExampleData();

    expect(store.items.map((item) => item.id), contains('user-item'));
    expect(store.items.where((item) => item.isSample), isEmpty);
  });

  testWidgets(
    'reviewer demo completes the sample and opens its lifecycle without photos',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = CareStore(
        repository: CareRepository(preferences),
        notificationScheduler: (_, __) async {},
      );
      await store.load();
      await tester.binding.setSurfaceSize(const Size(430, 1000));

      await tester.pumpWidget(MaterialApp(home: HomePage(store: store)));
      await tester.pumpAndSettle();

      const taskId = 'sample-filter:sample-filter-plan';
      final start = find.byKey(
        const ValueKey('start-maintenance-task-$taskId'),
      );
      await tester.scrollUntilVisible(
        start,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('示例 · 厨房净水器'), findsOneWidget);
      expect(find.text('更换滤芯'), findsOneWidget);
      await tester.tap(start);
      await tester.pumpAndSettle();

      for (var index = 0; index < 4; index++) {
        final step = find.byKey(
          ValueKey('execution-step-sample-filter-plan-step-$index'),
        );
        await tester.scrollUntilVisible(
          step,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(step);
      }
      await tester.scrollUntilVisible(
        find.byKey(const Key('execution-cost')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byKey(const Key('execution-cost')), '129');
      await tester.enterText(
        find.byKey(const Key('execution-material')),
        'PP 棉滤芯 A1',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('complete-maintenance')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('complete-maintenance')));
      await tester.pumpAndSettle();

      expect(find.text('本次保养已归档'), findsOneWidget);
      expect(find.text('¥129'), findsOneWidget);
      expect(find.text('查看生命周期'), findsOneWidget);
      await tester.tap(find.byKey(const Key('finish-maintenance-result')));
      await tester.pumpAndSettle();

      final saved = store.items.single;
      final record = saved.records.single;
      expect(record.cost, 129);
      expect(record.materialName, 'PP 棉滤芯 A1');
      expect(record.completedStepIds, hasLength(4));
      expect(
        saved.plans.single.dueDate,
        addMaintenanceDays(DateTime.now(), 180),
      );
      expect(
        find.byKey(const Key('maintenance-lifecycle-overview')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('maintenance-record-${record.id}')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('步骤：已完成 4 / 4'), findsOneWidget);
      expect(find.text('PP 棉滤芯 A1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('lifecycle renders frozen task and step facts after plan edits', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final record = MaintenanceRecord(
      id: 'record',
      planId: 'filter',
      completedAt: DateTime(2026, 8, 1),
      kind: '原任务标题',
      cost: 0,
      note: '',
      stepSnapshots: const [
        MaintenanceStepSnapshot(
          id: 'power',
          title: '原步骤标题',
          sortOrder: 0,
          completed: true,
        ),
      ],
    );
    final item = CareItem(
      id: 'item',
      name: '空调',
      category: '家电',
      location: '客厅',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [
        MaintenancePlan(
          id: 'filter',
          title: '新任务标题',
          intervalDays: 90,
          checklist: const [
            MaintenanceStep(id: 'power', title: '新步骤标题', sortOrder: 0),
          ],
        ),
      ],
      records: [record],
    );
    final store = CareStore(
      repository: CareRepository(preferences),
      notificationScheduler: (_, __) async {},
    )..items = [item];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MaintenanceLifecycleTimeline(item: item, controller: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('原任务标题'), findsOneWidget);
    expect(find.text('原步骤标题'), findsOneWidget);
    expect(find.text('新任务标题'), findsNothing);
    expect(find.text('新步骤标题'), findsNothing);
  });

  testWidgets('primary pages and the add-item flow render without overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});
    await tester.pumpWidget(const HearthioApp());
    await tester.pumpAndSettle();

    expect(find.text('家务志'), findsOneWidget);
    expect(find.text('添加物品'), findsOneWidget);

    await tester.tap(find.text('物品'));
    await tester.pumpAndSettle();
    expect(find.text('物品档案'), findsOneWidget);

    await tester.tap(find.text('添加物品'));
    await tester.pumpAndSettle();
    expect(find.text('选择物品'), findsWidgets);
    expect(find.text('常用物品'), findsOneWidget);
    expect(find.text('全部分类'), findsOneWidget);

    await tester.drag(
      find.byKey(const PageStorageKey('item-selection-scroll')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('item-category-厨房用品')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-category-厨房用品')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('catalog-item-厨房用品-炒锅')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('catalog-item-厨房用品-炒锅')));
    await tester.pumpAndSettle();
    expect(find.text('补充信息'), findsWidgets);
    expect(find.text('备注或自定义名称'), findsOneWidget);

    await tester.drag(
      find.byKey(const PageStorageKey('item-supplement-scroll')),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle-advanced-item-details')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byIcon(Icons.add_a_photo_outlined),
      280,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('item-supplement-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.byIcon(Icons.add_a_photo_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
    await tester.pumpAndSettle();
    expect(find.text('拍照'), findsOneWidget);
    expect(find.text('从相册选择'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('item search auto-fills category and keeps naming optional', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = CareStore();
    await tester.pumpWidget(MaterialApp(home: EditorPage(store: store)));

    await tester.enterText(find.byKey(const Key('item-search')), '体温计');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('search-item-医疗保健-体温计')));
    await tester.pumpAndSettle();

    expect(find.text('补充信息'), findsWidgets);
    expect(find.text('体温计'), findsOneWidget);
    expect(find.text('医疗保健'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('custom-item-name')), '儿童房体温计');
    await tester.enterText(find.byKey(const Key('item-location')), '儿童房');
    await tester.tap(find.byKey(const Key('save-care-item')));
    await tester.pumpAndSettle();

    expect(store.items.single.name, '儿童房体温计');
    expect(store.items.single.category, '医疗保健');
    expect(store.items.single.location, '儿童房');
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving a new item returns from the two-step editor route', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = CareStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open-item-editor'),
              onPressed: () {
                unawaited(
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => EditorPage(store: store)),
                  ),
                );
              },
              child: const Text('打开新增物品'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-item-editor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('common-item-冰箱')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-care-item')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open-item-editor')), findsOneWidget);
    expect(find.text('补充信息'), findsNothing);
    expect(store.items.single.name, '冰箱');
    expect(tester.takeException(), isNull);
  });

  testWidgets('first restore explains the file-selection flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(store: CareStore())),
    );
    await tester.tap(find.text('恢复备份'));
    await tester.pumpAndSettle();

    expect(find.text('如何恢复完整备份？'), findsOneWidget);
    expect(find.text('选择备份文件'), findsOneWidget);
    expect(find.textContaining('Hearthio-backup.zip'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy page has a local fallback before URL configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PrivacyPolicyPage(remoteUrl: '')),
    );

    expect(find.text('隐私政策页面正在准备中'), findsOneWidget);
    expect(find.textContaining('物品信息、照片、维护记录和计划默认保存在本机'), findsOneWidget);
  });

  testWidgets(
    'opening home does not mark notification permission as prompted',
    (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      await tester.pumpWidget(const HearthioApp());
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notification_permission_prompted'), isNull);
    },
  );

  testWidgets('first launch presents all three onboarding steps', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const HearthioApp());
    await tester.pumpAndSettle();

    expect(find.text('先给家里的物品建档'), findsOneWidget);
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('拍下凭证，留住细节'), findsOneWidget);
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('日历提醒，按时照料'), findsOneWidget);
    expect(find.text('开始整理'), findsOneWidget);
  });

  testWidgets('purifier template can be added and remains fully editable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = CareStore();
    await tester.pumpWidget(MaterialApp(home: EditorPage(store: store)));
    await tester.ensureVisible(find.byKey(const ValueKey('common-item-净水器')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('common-item-净水器')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('custom-item-name')), '厨房净水器');

    await tester.drag(
      find.byKey(const PageStorageKey('item-supplement-scroll')),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle-advanced-item-details')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('add-maintenance-plan')),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('add-maintenance-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-maintenance-plan')));
    await tester.pumpAndSettle();
    expect(find.text('选择保养模板'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('template-water-purifier-filter')),
    );
    await tester.pumpAndSettle();
    expect(find.text('编辑保养计划'), findsOneWidget);
    expect(find.text('更换滤芯'), findsOneWidget);
    expect(find.text('核对型号'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('maintenance-plan-title')),
      '更换复合滤芯',
    );
    await tester.enterText(
      find.byKey(const Key('maintenance-plan-interval')),
      '150',
    );
    await tester.enterText(
      find.byKey(const Key('maintenance-plan-reminder-lead')),
      '5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('maintenance-step-0')),
      '确认滤芯型号',
    );
    await tester.ensureVisible(
      find.byKey(const Key('maintenance-plan-enabled')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('maintenance-plan-enabled')));
    await tester.tap(find.byKey(const Key('save-maintenance-plan')));
    await tester.pumpAndSettle();

    expect(find.text('更换复合滤芯'), findsOneWidget);
    expect(find.textContaining('每 150 天'), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-care-item')));
    await tester.pumpAndSettle();
    expect(store.items.single.plans.single.title, '更换复合滤芯');
    expect(store.items.single.plans.single.intervalDays, 150);
    expect(store.items.single.plans.single.reminderLeadDays, 5);
    expect(store.items.single.plans.single.checklist.first.title, '确认滤芯型号');
    expect(store.items.single.plans.single.enabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan without history is deleted instead of archived', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final plan = MaintenancePlan(
      id: 'filter',
      title: '更换滤芯',
      intervalDays: 180,
      dueDate: DateTime(2026, 9, 1),
    );
    final item = CareItem(
      id: 'purifier',
      name: '净水器',
      category: '家电',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [plan],
    );
    final store = CareStore();
    await tester.pumpWidget(
      MaterialApp(
        home: EditorPage(store: store, item: item),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('remove-plan-filter')),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('remove-plan-filter')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('remove-plan-filter')));
    await tester.pumpAndSettle();
    expect(find.text('删除这个计划？'), findsOneWidget);
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(find.text('还没有保养计划'), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-care-item')));
    await tester.pumpAndSettle();
    expect(store.items.single.plans, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('linked plan is archived while its history stays intact', (
    tester,
  ) async {
    final plan = MaintenancePlan(
      id: 'filter',
      title: '更换滤芯',
      intervalDays: 180,
      dueDate: DateTime(2026, 9, 1),
    );
    final item = CareItem(
      id: 'purifier',
      name: '净水器',
      category: '家电',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [plan],
      records: [
        MaintenanceRecord(
          id: 'record-1',
          planId: 'filter',
          completedAt: DateTime(2026, 3, 1),
          cost: 0,
          note: '',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: EditorPage(store: CareStore(), item: item),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('remove-plan-filter')),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('remove-plan-filter')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('remove-plan-filter')));
    await tester.pumpAndSettle();
    expect(find.text('归档这个计划？'), findsOneWidget);
    await tester.tap(find.text('确认归档'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const PageStorageKey<String>('archived-maintenance-plans')),
      findsOneWidget,
    );
    expect(find.text('已归档计划（1）'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('item detail displays multiple plans without overwriting', (
    tester,
  ) async {
    final item = CareItem(
      id: 'air-conditioner',
      name: '空调',
      category: '家电',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [
        MaintenancePlan(
          id: 'filter',
          title: '清洗滤网',
          intervalDays: 90,
          dueDate: DateTime(2026, 9, 1),
        ),
        MaintenancePlan(
          id: 'deep-clean',
          title: '深度清洗',
          intervalDays: 365,
          dueDate: DateTime(2027, 1, 1),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailPage(store: CareStore(), item: item),
      ),
    );

    expect(find.byKey(const Key('detail-maintenance-plans')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-plan-filter')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('detail-plan-deep-clean')),
      findsOneWidget,
    );
    expect(find.text('清洗滤网'), findsWidgets);
    expect(find.text('深度清洗'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard sorts plan tasks by unified due-state priority', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final today = maintenanceDateOnly(DateTime.now());
    final item = CareItem(
      id: 'device',
      name: '设备',
      category: '家电',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [
        MaintenancePlan(
          id: 'planned',
          title: '已计划任务',
          intervalDays: 30,
          reminderLeadDays: 3,
          dueDate: today.add(const Duration(days: 30)),
        ),
        MaintenancePlan(
          id: 'soon',
          title: '即将到期任务',
          intervalDays: 30,
          reminderLeadDays: 3,
          dueDate: today.add(const Duration(days: 2)),
        ),
        MaintenancePlan(
          id: 'today',
          title: '今日任务',
          intervalDays: 30,
          dueDate: today,
        ),
        MaintenancePlan(
          id: 'overdue',
          title: '逾期任务',
          intervalDays: 30,
          dueDate: today.subtract(const Duration(days: 1)),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Dashboard(store: CareStore()..items = [item])),
    );
    await tester.pumpAndSettle();

    final overdue = tester.getTopLeft(
      find.byKey(const ValueKey('maintenance-task-device-overdue')),
    );
    final dueToday = tester.getTopLeft(
      find.byKey(const ValueKey('maintenance-task-device-today')),
    );
    final dueSoon = tester.getTopLeft(
      find.byKey(const ValueKey('maintenance-task-device-soon')),
    );
    final planned = tester.getTopLeft(
      find.byKey(const ValueKey('maintenance-task-device-planned')),
    );
    expect(overdue.dy, lessThan(dueToday.dy));
    expect(dueToday.dy, lessThan(dueSoon.dy));
    expect(dueSoon.dy, lessThan(planned.dy));
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('empty task center opens the first-plan item flow', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: Dashboard(store: CareStore())));
    await tester.pumpAndSettle();

    expect(find.text('还没有保养计划'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('create-first-maintenance-plan')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-first-maintenance-plan')));
    await tester.pumpAndSettle();

    expect(find.text('选择物品'), findsWidgets);
    await tester.ensureVisible(find.byKey(const ValueKey('common-item-净水器')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('common-item-净水器')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('item-supplement-scroll')),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle-advanced-item-details')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('add-maintenance-plan')),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('add-maintenance-plan')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'snoozing preserves original overdue date and creates no record',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final today = maintenanceDateOnly(DateTime.now());
      final dueDate = today.subtract(const Duration(days: 2));
      final item = CareItem(
        id: 'purifier',
        name: '净水器',
        category: '家电',
        location: '',
        brand: '',
        model: '',
        notes: '',
        photos: const [],
        plans: [
          MaintenancePlan(
            id: 'filter',
            title: '更换滤芯',
            intervalDays: 180,
            dueDate: dueDate,
          ),
        ],
      );
      final store = CareStore()..items = [item];
      await tester.pumpWidget(
        MaterialApp(
          home: AnimatedBuilder(
            animation: store,
            builder: (_, __) => Dashboard(store: store),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('defer-maintenance-task-purifier:filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('defer-maintenance-task-purifier:filter')),
      );
      await tester.pumpAndSettle();
      expect(find.text('稍后提醒'), findsWidgets);
      expect(find.textContaining('原到期日'), findsWidgets);
      await tester.tap(find.byKey(const Key('defer-until-tomorrow')));
      await tester.pumpAndSettle();

      final saved = store.items.single;
      expect(saved.plans.single.dueDate, dueDate);
      expect(
        saved.plans.single.deferredUntil,
        today.add(const Duration(days: 1)),
      );
      expect(saved.records, isEmpty);
      expect(find.text('已稍后提醒'), findsOneWidget);
      expect(find.textContaining('原状态 已逾期'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('start-maintenance-task-purifier:filter')),
      );
      await tester.tap(
        find.byKey(const ValueKey('start-maintenance-task-purifier:filter')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MaintenanceExecutionPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('calendar shows concrete task and matches detail status', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    final today = maintenanceDateOnly(DateTime.now());
    final otherDay = addMaintenanceDays(today, today.day == 1 ? 1 : -1);
    final item = CareItem(
      id: 'washer',
      name: '洗衣机',
      category: '家电',
      location: '',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [
        MaintenancePlan(
          id: 'drum',
          title: '内筒清洁',
          intervalDays: 30,
          dueDate: today,
        ),
        MaintenancePlan(
          id: 'drain-filter',
          title: '排水过滤器清洁',
          intervalDays: 30,
          dueDate: otherDay,
        ),
      ],
    );
    final store = CareStore()..items = [item];

    await tester.pumpWidget(MaterialApp(home: SchedulePage(store: store)));
    await tester.pumpAndSettle();
    expect(find.text('洗衣机'), findsOneWidget);
    expect(find.text('内筒清洁'), findsOneWidget);
    expect(find.text('今日到期'), findsOneWidget);

    await tester.tap(
      find.byKey(
        ValueKey(
          'calendar-day-${otherDay.year}-${otherDay.month}-${otherDay.day}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('排水过滤器清洁'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: DetailPage(store: store, item: item),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('detail-plan-status-drum')),
      findsOneWidget,
    );
    expect(find.textContaining('今日到期'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'execution keeps unchecked steps and records inputs plus before-after photos',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      final task = _executionTask();
      final controller = _FakeExecutionController(
        task: task,
        importedPaths: const ['/tmp/before.jpg', '/tmp/after.jpg'],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MaintenanceExecutionPage(controller: controller, task: task),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('厨房净水器'), findsOneWidget);
      expect(find.text('更换滤芯'), findsOneWidget);
      expect(find.textContaining('原计划日期'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('execution-step-water-off')));
      await tester.scrollUntilVisible(
        find.byKey(const Key('execution-cost')),
        280,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byKey(const Key('execution-cost')), '129');
      await tester.enterText(
        find.byKey(const Key('execution-material')),
        'PP 棉滤芯 A1',
      );
      await tester.enterText(find.byKey(const Key('execution-note')), '已冲洗');

      await tester.scrollUntilVisible(
        find.byKey(const Key('add-before-maintenance-photo')),
        280,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('add-before-maintenance-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('execution-photo-camera')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('add-after-maintenance-photo')),
        280,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('add-after-maintenance-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('execution-photo-gallery')));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('complete-maintenance')),
        280,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('complete-maintenance')));
      await tester.pumpAndSettle();
      expect(find.text('仍有步骤未勾选'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-incomplete-maintenance')));
      await tester.pumpAndSettle();

      final draft = controller.lastDraft!;
      expect(draft.cost, 129);
      expect(draft.materialName, 'PP 棉滤芯 A1');
      expect(draft.note, '已冲洗');
      expect(draft.completedStepIds, ['water-off']);
      expect(draft.beforePhotos, ['/tmp/before.jpg']);
      expect(draft.afterPhotos, ['/tmp/after.jpg']);
      expect(find.text('本次保养已归档'), findsOneWidget);
      expect(
        find.byKey(const Key('completion-notification-warning')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('execution failure stays editable and exposes retry state', (
    tester,
  ) async {
    final task = _executionTask();
    final controller = _FakeExecutionController(
      task: task,
      completionError: const MaintenanceCompletionException(
        '本次保养保存失败，数据未更新。请重试。',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MaintenanceExecutionPage(controller: controller, task: task),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('execution-step-water-off')));
    await tester.tap(find.byKey(const ValueKey('execution-step-flush')));
    await tester.scrollUntilVisible(
      find.byKey(const Key('complete-maintenance')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('complete-maintenance')));
    await tester.pumpAndSettle();

    expect(controller.completeCalls, 1);
    expect(
      find.byKey(const Key('maintenance-completion-error')),
      findsOneWidget,
    );
    expect(find.textContaining('数据未更新'), findsOneWidget);
    expect(find.text('完成本次保养'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('execution submit lock ignores consecutive taps', (tester) async {
    final task = _executionTask();
    final gate = Completer<void>();
    final controller = _FakeExecutionController(
      task: task,
      completionGate: gate,
      notificationScheduled: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MaintenanceExecutionPage(controller: controller, task: task),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('execution-step-water-off')));
    await tester.tap(find.byKey(const ValueKey('execution-step-flush')));
    await tester.scrollUntilVisible(
      find.byKey(const Key('complete-maintenance')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('complete-maintenance')));
    await tester.tap(find.byKey(const Key('complete-maintenance')));
    expect(controller.completeCalls, 1);
    gate.complete();
    await tester.pumpAndSettle();

    expect(controller.completeCalls, 1);
    expect(find.text('本次保养已归档'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification tap opens the exact maintenance execution page', (
    tester,
  ) async {
    final task = _executionTask();
    final sibling = MaintenancePlan(
      id: 'deep-clean',
      title: '深度清洗',
      intervalDays: 365,
      dueDate: addMaintenanceDays(DateTime.now(), 30),
    );
    final item = task.item.copyWith(plans: [task.plan, sibling]);
    final store = CareStore()
      ..loaded = true
      ..items = [item];
    await tester.pumpWidget(MaterialApp(home: HomePage(store: store)));
    await tester.pump();

    store.handleNotificationPayload(
      MaintenanceNotificationPayload(
        itemId: item.id,
        planId: task.plan.id,
      ).encode(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaintenanceExecutionPage), findsOneWidget);
    expect(find.text('厨房净水器'), findsOneWidget);
    expect(find.text('更换滤芯'), findsOneWidget);
    expect(find.text('深度清洗'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleted notification target returns to schedule with a reason', (
    tester,
  ) async {
    final store = CareStore()
      ..loaded = true
      ..items = [];
    await tester.pumpWidget(MaterialApp(home: HomePage(store: store)));
    await tester.pump();

    store.handleNotificationPayload(
      const MaintenanceNotificationPayload(
        itemId: 'deleted-item',
        planId: 'deleted-plan',
      ).encode(),
    );
    await tester.pumpAndSettle();

    expect(find.text('保养日程'), findsOneWidget);
    expect(find.textContaining('物品已删除'), findsOneWidget);
    expect(find.byType(MaintenanceExecutionPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lifecycle detail explains an empty traceable timeline', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    final item = CareItem(
      id: 'empty-lifecycle',
      name: '书房加湿器',
      category: '家电',
      location: '书房',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: const [],
    );
    final store = CareStore()
      ..loaded = true
      ..items = [item];

    await tester.pumpWidget(
      MaterialApp(
        home: DetailPage(store: store, item: item),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('maintenance-lifecycle-overview')),
      findsOneWidget,
    );
    expect(find.text('未填写购买日期'), findsOneWidget);
    expect(find.text('0 次'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('maintenance-timeline-empty')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('还没有生命周期事件'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('timeline shows plan, long facts, steps and multiple photos', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    final filter = MaintenancePlan(
      id: 'filter',
      title: '清洗滤网',
      intervalDays: 90,
      dueDate: DateTime(2026, 9, 1),
      checklist: const [
        MaintenanceStep(id: 'power', title: '断开设备电源', sortOrder: 0),
        MaintenanceStep(id: 'wash', title: '使用清水完整冲洗并等待滤网彻底晾干', sortOrder: 1),
      ],
    );
    final deepClean = MaintenancePlan(
      id: 'deep-clean',
      title: '深度清洁',
      intervalDays: 365,
      dueDate: DateTime(2027, 1, 1),
    );
    final longNote = '已检查出风口、风轮和排水状态；这是一段用于验证时间线长文本能够完整换行且不会被省略的真实备注。';
    final item = CareItem(
      id: 'rich-lifecycle',
      name: '客厅空调',
      category: '家电',
      location: '客厅',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [filter, deepClean],
      records: [
        MaintenanceRecord(
          id: 'filter-record',
          planId: 'filter',
          completedAt: DateTime(2026, 6, 1),
          kind: '清洗滤网',
          cost: 128.5,
          materialName: '环保型空调滤网清洁剂 500ml 加长型号',
          note: longNote,
          completedStepIds: const ['power'],
          beforePhotos: const ['/tmp/before-1.jpg', '/tmp/before-2.jpg'],
          afterPhotos: const ['/tmp/after-1.jpg', '/tmp/after-2.jpg'],
        ),
        MaintenanceRecord(
          id: 'deep-record',
          planId: 'deep-clean',
          completedAt: DateTime(2026, 2, 1),
          kind: '深度清洁',
          cost: 300,
          note: '',
        ),
      ],
      purchaseDate: DateTime(2025, 1, 1),
    );
    final store = CareStore()
      ..loaded = true
      ..items = [item];

    await tester.pumpWidget(
      MaterialApp(
        home: DetailPage(store: store, item: item),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('maintenance-record-filter-record')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('清洗滤网'), findsWidgets);
    expect(find.text(longNote), findsOneWidget);
    expect(find.text('步骤：已完成 1 / 2'), findsOneWidget);
    expect(find.text('保养前照片 · 2 张'), findsOneWidget);
    expect(find.text('保养后照片 · 2 张'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('maintenance-record-deep-record')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('深度清洁'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('maintenance-purchase-timeline-entry')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('购买起点'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('record edit refreshes facts and delete rolls plan back', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    final plan = MaintenancePlan(
      id: 'filter',
      title: '清洗滤网',
      intervalDays: 90,
      lastCompletedAt: DateTime(2026, 6, 1),
      dueDate: DateTime(2026, 8, 30),
      checklist: const [
        MaintenanceStep(id: 'power', title: '断电', sortOrder: 0),
      ],
    );
    final item = CareItem(
      id: 'editable-lifecycle',
      name: '卧室空调',
      category: '家电',
      location: '卧室',
      brand: '',
      model: '',
      notes: '',
      photos: const [],
      plans: [plan],
      records: [
        MaintenanceRecord(
          id: 'latest-record',
          planId: 'filter',
          completedAt: DateTime(2026, 6, 1),
          cost: 60,
          note: '原备注',
          completedStepIds: const ['power'],
        ),
        MaintenanceRecord(
          id: 'older-record',
          planId: 'filter',
          completedAt: DateTime(2026, 3, 1),
          cost: 30,
          note: '上一次记录',
          completedStepIds: const ['power'],
        ),
      ],
    );
    final store =
        CareStore(
            repository: CareRepository(preferences),
            notificationScheduler: (_, __) async {},
          )
          ..loaded = true
          ..items = [item];
    await tester.pumpWidget(
      MaterialApp(
        home: DetailPage(store: store, item: item),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('edit-maintenance-record-latest-record')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('edit-maintenance-record-latest-record')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('record-editor-cost')), '75.5');
    await tester.enterText(
      find.byKey(const Key('record-editor-note')),
      '修正后的详细备注',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-maintenance-record')),
      450,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('save-maintenance-record')));
    await tester.pumpAndSettle();

    expect(store.items.single.records.first.cost, 75.5);
    expect(store.items.single.records.first.note, '修正后的详细备注');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('delete-maintenance-record-latest-record')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('delete-maintenance-record-latest-record')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('confirm-delete-maintenance-record')),
    );
    await tester.pumpAndSettle();

    final saved = store.items.single;
    expect(saved.records.map((record) => record.id), ['older-record']);
    expect(saved.plans.single.lastCompletedAt, DateTime(2026, 3, 1));
    expect(saved.plans.single.dueDate, DateTime(2026, 5, 30));
    expect(
      find.byKey(const ValueKey('maintenance-record-latest-record')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('plan editor has no overflow on small iPhone and iPad sizes', (
    tester,
  ) async {
    final template = maintenanceTemplates.first;
    final plan = template.createPlan(
      planId: 'layout-plan',
      referenceDate: DateTime(2026, 1, 1),
    );
    for (final size in [const Size(320, 568), const Size(1024, 1366)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(home: MaintenancePlanEditorPage(initialPlan: plan)),
      );
      await tester.pumpAndSettle();
      expect(find.text('编辑保养计划'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
