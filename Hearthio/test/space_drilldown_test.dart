import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/app/locale_controller.dart';
import 'package:hearthio/l10n/app_localizations.dart';
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
  test(
    'resetting an English sample reuses the existing Chinese kitchen space',
    () async {
      SharedPreferences.setMockInitialValues({
        AppLocaleController.preferenceKey:
            AppLanguageMode.simplifiedChinese.name,
      });
      final preferences = await SharedPreferences.getInstance();
      final store = CareStore(repository: CareRepository(preferences));

      await store.load();

      expect(store.spaces.single.name, '厨房');
      expect(store.items.single.spaceId, store.spaces.single.id);
      final kitchenSpaceId = store.spaces.single.id;

      await store.deleteExampleData();
      store.updateLocalizations(lookupAppLocalizations(const Locale('en')));
      await store.resetExampleData();

      expect(store.spaces, hasLength(1));
      expect(store.spaces.single.id, kitchenSpaceId);
      expect(store.items.single.location, 'Kitchen');
      expect(store.items.single.spaceId, kitchenSpaceId);
      expect(store.locationLabelFor(store.items.single), 'Kitchen');

      store.updateLocalizations(lookupAppLocalizations(const Locale('zh')));
      expect(store.locationLabelFor(store.items.single), '厨房');
    },
  );

  test('existing localized default-space duplicates merge on load', () async {
    const chineseKitchen = CareSpace(id: 'kitchen-zh', type: '厨房', name: '厨房');
    const englishKitchen = CareSpace(
      id: 'kitchen-en',
      type: '厨房',
      name: 'Kitchen',
    );
    final item = _item(
      id: 'sample-filter',
      name: 'Sample · Kitchen water purifier',
      location: 'Kitchen',
      spaceId: englishKitchen.id,
    );
    SharedPreferences.setMockInitialValues({
      AppLocaleController.preferenceKey: AppLanguageMode.simplifiedChinese.name,
      CareRepository.storageKey: CareDataEnvelope(
        items: [item],
        spaces: const [chineseKitchen, englishKitchen],
      ).encode(),
    });
    final preferences = await SharedPreferences.getInstance();
    final store = CareStore(repository: CareRepository(preferences));

    await store.load();

    expect(store.spaces.map((space) => space.id), [chineseKitchen.id]);
    expect(store.spaces.single.name, chineseKitchen.name);
    expect(store.items.single.spaceId, chineseKitchen.id);
    expect(store.locationLabelFor(store.items.single), '厨房');
    final persisted = CareDataEnvelope.decode(
      preferences.getString(CareRepository.storageKey)!,
    );
    expect(persisted.spaces, hasLength(1));
    expect(persisted.items.single.spaceId, chineseKitchen.id);
  });

  test('custom spaces of a known type are never merged as defaults', () {
    const customKitchen = CareSpace(id: 'prep-area', type: '厨房', name: '备餐区');
    final result = migrateLegacyItemLocations(
      [_item(id: 'sample', name: 'Sample', location: 'Kitchen')],
      existingSpaces: const [customKitchen],
    );

    expect(result.spaces.map((space) => space.name), ['备餐区', 'Kitchen']);
    expect(result.items.single.spaceId, isNot(customKitchen.id));
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
      final directory = await Directory.systemTemp.createTemp(
        'hearthio-space-migration-',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final snapshot = File(
        '${directory.path}/${CareRepository.snapshotFileName}',
      );
      final repository = await CareRepository.open(snapshotFile: snapshot);

      final result = await repository.load(initialItems: const []);

      expect(result.spaces.map((space) => space.name), ['客厅', '自建工具房']);
      expect(result.items.first.location, '客厅-阳台');
      expect(result.items.first.locationDetail, '阳台');
      expect(result.items.first.spaceId, result.spaces.first.id);
      expect(result.items.last.locationDetail, isEmpty);
      expect(result.items.last.spaceId, result.spaces.last.id);

      final persisted =
          jsonDecode(await snapshot.readAsString()) as Map<String, dynamic>;
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
        AppLocaleController.preferenceKey:
            AppLanguageMode.simplifiedChinese.name,
        CareRepository.storageKey: const CareDataEnvelope(items: []).encode(),
      });
      final preferences = await SharedPreferences.getInstance();
      final store = CareStore(repository: CareRepository(preferences));
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

  test(
    'saving a duplicate actual space name returns a specific error',
    () async {
      const room = CareSpace(id: 'living-room', type: '客厅', name: '客厅');
      final store = CareStore()..spaces = [room];

      await expectLater(
        store.saveSpace(
          const CareSpace(id: 'another-room', type: '客厅', name: ' 客厅 '),
        ),
        throwsA(
          isA<DuplicateSpaceNameException>().having(
            (error) => error.name,
            'name',
            '客厅',
          ),
        ),
      );

      expect(store.spaces, [room]);
    },
  );

  test(
    'localized default names conflict but distinct actual names stay allowed',
    () async {
      const room = CareSpace(id: 'living-room', type: '客厅', name: '客厅');
      SharedPreferences.setMockInitialValues({
        CareRepository.storageKey: const CareDataEnvelope(
          items: [],
          spaces: [room],
        ).encode(),
      });
      final preferences = await SharedPreferences.getInstance();
      final store = CareStore(repository: CareRepository(preferences));
      await store.load();

      await expectLater(
        store.saveSpace(
          const CareSpace(
            id: 'english-living-room',
            type: '客厅',
            name: 'Living room',
          ),
        ),
        throwsA(isA<DuplicateSpaceNameException>()),
      );

      await store.saveSpace(
        const CareSpace(id: 'second-living-room', type: '客厅', name: '起居室'),
      );
      expect(store.spaces.map((space) => space.name), ['客厅', '起居室']);
    },
  );

  testWidgets('English default name detects an existing Chinese default space', (
    tester,
  ) async {
    addTearDown(AppToast.dismiss);
    const room = CareSpace(id: 'living-room', type: '客厅', name: '客厅');
    final store = CareStore()
      ..loaded = true
      ..spaces = [room];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: AddSpacePage(store: store),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-space')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Living room'), findsWidgets);
    expect(
      find.text(
        'A space with this actual name already exists. If you have more than one similar space, change the actual name to tell them apart.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AddSpacePage), findsOneWidget);
    expect(store.spaces, [room]);
    expect(tester.takeException(), isNull);
  });

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
      AppLocaleController.preferenceKey: AppLanguageMode.simplifiedChinese.name,
      CareRepository.storageKey: const CareDataEnvelope(items: []).encode(),
    });
    const room = CareSpace(id: 'living-room', type: '客厅', name: '客厅');
    final preferences = await SharedPreferences.getInstance();
    final store = CareStore(repository: CareRepository(preferences));
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
