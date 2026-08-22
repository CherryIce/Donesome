import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

CareItem _item({
  required String id,
  required String name,
  String location = '',
  String? spaceId,
  String locationDetail = '',
  double? purchasePrice,
  double? currentValue,
  List<MaintenanceRecord> records = const [],
}) => CareItem(
  id: id,
  name: name,
  category: '家用电器',
  location: location,
  spaceId: spaceId,
  locationDetail: locationDetail,
  brand: '',
  model: '',
  notes: '',
  photos: const [],
  purchasePrice: purchasePrice,
  currentValue: currentValue,
  records: records,
);

void main() {
  test('seeded and reset sample stays linked to the kitchen space', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CareStore();

    await store.load();

    expect(store.spaces.single.name, '厨房');
    expect(store.items.single.spaceId, store.spaces.single.id);
    await store.resetExampleData();
    expect(store.items.single.spaceId, store.spaces.single.id);
    expect(store.locationLabelFor(store.items.single), '厨房');
  });

  test(
    'v2 locations migrate conservatively into actual spaces and details',
    () async {
      final v2 = jsonEncode({
        'schemaVersion': 2,
        'items': [
          {'id': 'washer', 'name': '洗衣机', 'location': '客厅-阳台'},
          {'id': 'toolbox', 'name': '工具箱', 'location': '自建工具房'},
        ],
      });
      SharedPreferences.setMockInitialValues({CareRepository.storageKey: v2});
      final repository = await CareRepository.open();

      final result = await repository.load(initialItems: const []);

      expect(result.spaces.map((space) => space.name), ['客厅', '自建工具房']);
      expect(result.items.first.location, '客厅-阳台');
      expect(result.items.first.locationDetail, '阳台');
      expect(result.items.first.spaceId, result.spaces.first.id);
      expect(result.items.last.locationDetail, isEmpty);
      expect(result.items.last.spaceId, result.spaces.last.id);

      final preferences = await SharedPreferences.getInstance();
      final persisted =
          jsonDecode(preferences.getString(CareRepository.storageKey)!)
              as Map<String, dynamic>;
      expect(persisted['schemaVersion'], currentCareSchemaVersion);
      expect(persisted['spaces'], hasLength(2));
    },
  );

  test('backup round-trip preserves actual spaces and item references', () {
    const room = CareSpace(id: 'living-room', type: '客厅', name: '客厅');
    final item = _item(
      id: 'washer',
      name: '洗衣机',
      location: '客厅 · 阳台',
      spaceId: room.id,
      locationDetail: '阳台',
    );

    final decoded = CareBackupCodec.decode(
      CareBackupCodec.encode(
        items: [item],
        spaces: const [room],
        photoBytesByPath: const {},
      ),
    );

    expect(decoded.spaces.single.name, '客厅');
    expect(decoded.items.single.spaceId, room.id);
    expect(decoded.items.single.locationDetail, '阳台');
  });

  test(
    'renaming a space updates linked item display and deletion keeps item',
    () async {
      SharedPreferences.setMockInitialValues({
        CareRepository.storageKey: const CareDataEnvelope(items: []).encode(),
      });
      final store = CareStore();
      await store.load();
      const room = CareSpace(id: 'living-room', type: '客厅', name: '客厅');
      await store.saveSpace(room);
      await store.save(
        _item(
          id: 'washer',
          name: '洗衣机',
          location: '客厅 · 阳台',
          spaceId: room.id,
          locationDetail: '阳台',
        ),
      );

      await store.saveSpace(room.copyWith(name: '起居室'));
      expect(store.locationLabelFor(store.items.single), '起居室 · 阳台');

      await store.removeSpace(room.id);
      expect(store.spaces, isEmpty);
      expect(store.items, hasLength(1));
      expect(store.items.single.spaceId, isNull);
      expect(store.locationLabelFor(store.items.single), '未设置空间 · 阳台');
    },
  );

  testWidgets('home overview opens items, spaces, year report and assets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final room = const CareSpace(id: 'living-room', type: '客厅', name: '客厅');
    final store = CareStore()
      ..loaded = true
      ..spaces = [room]
      ..items = [
        _item(
          id: 'washer',
          name: '洗衣机',
          spaceId: room.id,
          location: '客厅 · 阳台',
          locationDetail: '阳台',
          currentValue: 1200,
          records: [
            MaintenanceRecord(
              id: 'this-year',
              completedAt: DateTime(2026, 2, 1),
              cost: 100,
              note: '',
            ),
            MaintenanceRecord(
              id: 'last-year',
              completedAt: DateTime(2025, 10, 1),
              cost: 70,
              note: '',
            ),
          ],
        ),
      ];

    Future<void> openHomeFact(Key key) async {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(MaterialApp(home: HomePage(store: store)));
    await tester.pumpAndSettle();

    await openHomeFact(const Key('dashboard-fact-items'));
    expect(find.text('全部物品'), findsOneWidget);

    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    await openHomeFact(const Key('dashboard-fact-assets'));
    expect(find.byKey(const Key('asset-valuation-view')), findsOneWidget);
    expect(find.text('¥1200'), findsWidgets);

    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    await openHomeFact(const Key('dashboard-fact-annual-cost'));
    expect(find.text('本年维护'), findsOneWidget);
    expect(find.text('¥100'), findsWidgets);

    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    await openHomeFact(const Key('dashboard-fact-spaces'));
    expect(find.text('家庭空间'), findsOneWidget);
    expect(find.byKey(const ValueKey('space-living-room')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('item editor selects an actual space and keeps detail text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      CareRepository.storageKey: const CareDataEnvelope(items: []).encode(),
    });
    const room = CareSpace(id: 'living-room', type: '客厅', name: '客厅');
    final store = CareStore();
    await store.load();
    await store.saveSpace(room);

    await tester.pumpWidget(MaterialApp(home: EditorPage(store: store)));
    await tester.tap(find.byKey(const ValueKey('common-item-洗衣机')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item-space-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-space-living-room')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('item-location')), '阳台');
    await tester.tap(find.byKey(const Key('save-care-item')));
    await tester.pumpAndSettle();

    expect(store.items.single.spaceId, room.id);
    expect(store.items.single.locationDetail, '阳台');
    expect(store.locationLabelFor(store.items.single), '客厅 · 阳台');
    expect(tester.takeException(), isNull);
  });
}
