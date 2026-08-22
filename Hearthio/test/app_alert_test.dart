import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/widgets/app_alert.dart';

void main() {
  testWidgets('app alert follows title message actions hierarchy', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAppAlert<bool>(
                  context,
                  key: const Key('test-app-alert'),
                  title: '删除这个计划？',
                  message: '“清洗滤网”尚无维护记录，删除后无法恢复。',
                  actions: const [
                    AppAlertAction(
                      label: '取消',
                      result: false,
                      key: Key('cancel-alert'),
                    ),
                    AppAlertAction(
                      label: '确认删除',
                      result: true,
                      key: Key('confirm-alert'),
                      tone: AppAlertActionTone.destructive,
                    ),
                  ],
                );
              },
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('test-app-alert')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      tester.getTopLeft(find.text('删除这个计划？')).dy,
      lessThan(tester.getTopLeft(find.textContaining('清洗滤网')).dy),
    );
    expect(
      tester.getTopLeft(find.textContaining('清洗滤网')).dy,
      lessThan(tester.getTopLeft(find.text('取消')).dy),
    );

    final cancelSize = tester.getSize(find.byKey(const Key('cancel-alert')));
    final confirmSize = tester.getSize(find.byKey(const Key('confirm-alert')));
    expect(cancelSize.height, greaterThanOrEqualTo(60));
    expect(confirmSize.height, greaterThanOrEqualTo(60));
    expect(cancelSize.width, closeTo(confirmSize.width, 1));

    final cancel = tester.widget<TextButton>(
      find.byKey(const Key('cancel-alert')),
    );
    final confirm = tester.widget<TextButton>(
      find.byKey(const Key('confirm-alert')),
    );
    expect(cancel.style?.foregroundColor?.resolve({}), const Color(0xFF137B67));
    expect(
      confirm.style?.foregroundColor?.resolve({}),
      const Color(0xFFB42318),
    );

    await tester.tap(find.byKey(const Key('confirm-alert')));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('long alert content scrolls without hiding actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppAlertDialog<void>(
            title: '如何恢复完整备份？',
            message:
                '接下来会打开“文件”选择器。\n\n1. 找到此前通过“完整备份”导出的 Hearthio-backup.zip。\n2. 选择该文件后，物品、维护记录和凭证照片会一起恢复。\n3. 当前设备上的档案将被替换；如需保留，请先导出一次当前完整备份。',
            actions: [
              AppAlertAction(
                label: '知道了',
                result: null,
                key: Key('single-alert-action'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('知道了'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('single-alert-action'))).width,
      closeTo(
        tester.getSize(find.byKey(const Key('app-alert-surface'))).width,
        1,
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('app-alert-surface'))).height,
      lessThanOrEqualTo(432),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('three actions stack as full-width footer rows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppAlertDialog<int>(
            title: '选择操作',
            message: '每个操作都应保持完整的底部点击区域。',
            actions: [
              AppAlertAction(label: '稍后处理', result: 0, key: Key('action-0')),
              AppAlertAction(label: '查看详情', result: 1, key: Key('action-1')),
              AppAlertAction(label: '继续', result: 2, key: Key('action-2')),
            ],
          ),
        ),
      ),
    );

    final surfaceWidth = tester
        .getSize(find.byKey(const Key('app-alert-surface')))
        .width;
    for (var index = 0; index < 3; index++) {
      expect(
        tester.getSize(find.byKey(Key('action-$index'))).width,
        closeTo(surfaceWidth, 1),
      );
    }
    expect(
      tester.getTopLeft(find.byKey(const Key('action-0'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('action-1'))).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('action-1'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('action-2'))).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
