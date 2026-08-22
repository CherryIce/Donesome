import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

CareItem _itemWithPlans(List<MaintenancePlan> plans) => CareItem(
  id: 'air-conditioner',
  name: '客厅空调',
  category: '家电',
  location: '客厅',
  brand: '',
  model: '',
  notes: '',
  photos: const [],
  plans: plans,
);

void main() {
  group('maintenance notification payload', () {
    test('round-trips the versioned item and plan identity', () {
      const source = MaintenanceNotificationPayload(
        itemId: 'item:air-conditioner',
        planId: 'plan:filter',
      );

      final decoded = MaintenanceNotificationPayload.tryDecode(source.encode());

      expect(decoded, isNotNull);
      expect(decoded!.version, MaintenanceNotificationPayload.currentVersion);
      expect(decoded.itemId, source.itemId);
      expect(decoded.planId, source.planId);
    });

    test('rejects malformed, unsupported, blank and oversized payloads', () {
      expect(MaintenanceNotificationPayload.tryDecode('{'), isNull);
      expect(
        MaintenanceNotificationPayload.tryDecode(
          jsonEncode({'version': 2, 'itemId': 'item', 'planId': 'plan'}),
        ),
        isNull,
      );
      expect(
        MaintenanceNotificationPayload.tryDecode(
          jsonEncode({'version': 1, 'itemId': ' ', 'planId': 'plan'}),
        ),
        isNull,
      );
      expect(
        MaintenanceNotificationPayload.tryDecode(
          'x' * (MaintenanceNotificationPayload.maxPayloadBytes + 1),
        ),
        isNull,
      );
    });
  });

  group('maintenance notification resolution', () {
    final filter = MaintenancePlan(
      id: 'filter',
      title: '清洗滤网',
      intervalDays: 90,
      dueDate: DateTime(2026, 9, 1),
    );
    final deepClean = MaintenancePlan(
      id: 'deep-clean',
      title: '深度清洗',
      intervalDays: 365,
      dueDate: DateTime(2027, 1, 1),
    );

    test('selects the exact plan without crossing sibling tasks', () {
      final item = _itemWithPlans([filter, deepClean]);
      final resolution = resolveMaintenanceNotification(
        const MaintenanceNotificationPayload(
          itemId: 'air-conditioner',
          planId: 'deep-clean',
        ).encode(),
        [item],
      );

      expect(resolution.type, MaintenanceNotificationResolutionType.ready);
      expect(resolution.task!.item.id, 'air-conditioner');
      expect(resolution.task!.plan.id, 'deep-clean');
    });

    test('deleted item and deleted or inactive plan safely degrade', () {
      final activeItem = _itemWithPlans([filter]);
      final deletedItem = resolveMaintenanceNotification(
        const MaintenanceNotificationPayload(
          itemId: 'missing',
          planId: 'filter',
        ).encode(),
        [activeItem],
      );
      final deletedPlan = resolveMaintenanceNotification(
        const MaintenanceNotificationPayload(
          itemId: 'air-conditioner',
          planId: 'missing',
        ).encode(),
        [activeItem],
      );
      final disabledItem = _itemWithPlans([filter.copyWith(enabled: false)]);
      final disabledPlan = resolveMaintenanceNotification(
        const MaintenanceNotificationPayload(
          itemId: 'air-conditioner',
          planId: 'filter',
        ).encode(),
        [disabledItem],
      );

      expect(
        deletedItem.type,
        MaintenanceNotificationResolutionType.itemUnavailable,
      );
      expect(
        deletedPlan.type,
        MaintenanceNotificationResolutionType.planUnavailable,
      );
      expect(
        disabledPlan.type,
        MaintenanceNotificationResolutionType.planUnavailable,
      );
    });

    test('store keeps a tap queued until its data has loaded', () {
      final store = CareStore();
      store.items = [
        _itemWithPlans([filter]),
      ];
      store.handleNotificationPayload(
        const MaintenanceNotificationPayload(
          itemId: 'air-conditioner',
          planId: 'filter',
        ).encode(),
      );

      expect(store.takeNotificationNavigation(), isNull);
      store.loaded = true;
      expect(
        store.takeNotificationNavigation()!.type,
        MaintenanceNotificationResolutionType.ready,
      );
      expect(store.hasPendingNotificationNavigation, isFalse);
    });
  });

  test(
    'notification ids are stable and separate delimiter-shaped identities',
    () {
      final first = notificationIdForPlan('a:b', 'c');
      final second = notificationIdForPlan('a', 'b:c');

      expect(notificationIdForPlan('a:b', 'c'), first);
      expect(first, greaterThan(0));
      expect(first, isNot(second));
    },
  );

  test(
    'consecutive saves serialize reminder mutations in edit order',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final firstStarted = Completer<void>();
      final secondStarted = Completer<void>();
      final releaseFirst = Completer<void>();
      final scheduledNames = <String>[];
      final plan = MaintenancePlan(
        id: 'filter',
        title: '清洗滤网',
        intervalDays: 90,
        dueDate: DateTime(2026, 9, 1),
      );
      final original = _itemWithPlans([plan]);
      final store =
          CareStore(
              repository: CareRepository(preferences),
              notificationScheduler: (item, _) async {
                scheduledNames.add(item.name);
                if (item.name == '第一次编辑') {
                  firstStarted.complete();
                  await releaseFirst.future;
                } else if (item.name == '第二次编辑') {
                  secondStarted.complete();
                }
              },
            )
            ..loaded = true
            ..items = [original];

      await store.save(original.copyWith(name: '第一次编辑'));
      await firstStarted.future;
      await store.save(original.copyWith(name: '第二次编辑'));
      await Future<void>.delayed(Duration.zero);
      expect(scheduledNames, ['第一次编辑']);

      releaseFirst.complete();
      await secondStarted.future;
      expect(scheduledNames, ['第一次编辑', '第二次编辑']);
    },
  );

  test(
    'permission checks and reminder writes share one ordered queue',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final firstPermissionStarted = Completer<void>();
      final releaseFirstPermission = Completer<void>();
      final secondScheduled = Completer<void>();
      final scheduledNames = <String>[];
      var permissionCalls = 0;
      final original = _itemWithPlans([
        MaintenancePlan(
          id: 'filter',
          title: '清洗滤网',
          intervalDays: 90,
          dueDate: DateTime(2026, 9, 1),
        ),
      ]);
      final store = CareStore(
        repository: CareRepository(preferences),
        notificationAccessResolver: () async {
          permissionCalls += 1;
          if (permissionCalls == 1) {
            firstPermissionStarted.complete();
            await releaseFirstPermission.future;
          }
          return NotificationAccess.enabled;
        },
        notificationScheduler: (item, _) async {
          scheduledNames.add(item.name);
          if (item.name == '第二次编辑') secondScheduled.complete();
        },
      )..items = [original];

      await store.save(original.copyWith(name: '第一次编辑'));
      await firstPermissionStarted.future;
      await store.save(original.copyWith(name: '第二次编辑'));
      await Future<void>.delayed(Duration.zero);

      expect(scheduledNames, isEmpty);
      releaseFirstPermission.complete();
      await secondScheduled.future;
      expect(scheduledNames, ['第一次编辑', '第二次编辑']);
    },
  );
}
