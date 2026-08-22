import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/widgets/app_date_picker.dart';

void main() {
  testWidgets('shared picker stages a date until the user confirms', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAppDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 8, 22),
                  firstDate: DateTime(2026, 1, 1),
                  lastDate: DateTime(2026, 12, 31),
                  currentDate: DateTime(2026, 8, 22),
                );
              },
              child: const Text('打开日期选择器'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开日期选择器'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-date-picker-sheet')), findsOneWidget);
    expect(find.text('选择日期'), findsOneWidget);
    expect(find.text('2026年8月'), findsOneWidget);
    expect(result, isNull);
    final dayHitSize = tester.getSize(
      find.byKey(const Key('app-date-picker-day-hit-2026-8-23')),
    );
    expect(dayHitSize.width, greaterThanOrEqualTo(44));
    expect(dayHitSize.height, greaterThanOrEqualTo(44));

    await tester.tap(find.byKey(const Key('app-date-picker-day-2026-8-23')));
    await tester.pump();
    expect(result, isNull);

    await tester.tap(find.byKey(const Key('app-date-picker-confirm')));
    await tester.pumpAndSettle();

    expect(result, DateTime(2026, 8, 23));
    expect(find.byKey(const Key('app-date-picker-sheet')), findsNothing);
  });

  testWidgets('shared picker keeps caller date bounds across months', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAppDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 8, 31),
                  firstDate: DateTime(2026, 8, 23),
                  lastDate: DateTime(2026, 9, 2),
                  currentDate: DateTime(2026, 8, 22),
                );
              },
              child: const Text('打开日期选择器'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开日期选择器'));
    await tester.pumpAndSettle();

    final todayButton = tester.widget<TextButton>(
      find.byKey(const Key('app-date-picker-today')),
    );
    expect(todayButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('app-date-picker-next-month')));
    await tester.pump();
    expect(find.text('2026年9月'), findsOneWidget);

    await tester.tap(find.byKey(const Key('app-date-picker-day-2026-9-2')));
    await tester.tap(find.byKey(const Key('app-date-picker-confirm')));
    await tester.pumpAndSettle();

    expect(result, DateTime(2026, 9, 2));
  });

  testWidgets('cancel closes the shared picker without returning a date', (
    tester,
  ) async {
    var completed = false;
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAppDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 8, 22),
                  firstDate: DateTime(2026, 1, 1),
                  lastDate: DateTime(2026, 12, 31),
                  currentDate: DateTime(2026, 8, 22),
                );
                completed = true;
              },
              child: const Text('打开日期选择器'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开日期选择器'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('app-date-picker-cancel')));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
  });

  testWidgets('shared picker fits compact iPhone and iPad viewports', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [
      Size(375, 667),
      Size(667, 375),
      Size(834, 1194),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 8, 22),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100, 12, 31),
                  currentDate: DateTime(2026, 8, 22),
                ),
                child: const Text('打开日期选择器'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开日期选择器'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'viewport: $size');
      expect(
        tester.getRect(find.byKey(const Key('app-date-picker-sheet'))).height,
        lessThanOrEqualTo(size.height),
      );

      await tester.ensureVisible(
        find.byKey(const Key('app-date-picker-cancel')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('app-date-picker-cancel')));
      await tester.pumpAndSettle();
    }
  });
}
