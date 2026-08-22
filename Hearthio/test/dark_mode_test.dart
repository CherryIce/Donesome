import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/main.dart';
import 'package:hearthio/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('light and dark palettes keep readable surface contrast', () {
    expect(HearthioTheme.light.brightness, Brightness.light);
    expect(HearthioTheme.dark.brightness, Brightness.dark);
    expect(HearthioPalette.light.paper, isNot(HearthioPalette.dark.paper));
    expect(HearthioPalette.light.ink, isNot(HearthioPalette.dark.ink));
    expect(
      _contrast(HearthioPalette.light.ink, HearthioPalette.light.paper),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(HearthioPalette.dark.ink, HearthioPalette.dark.paper),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('app follows the system dark appearance', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_seen': false});
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const HearthioApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, HearthioPalette.dark.canvas);
  });

  testWidgets('custom alert and date sheet use dark semantic surfaces', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: HearthioTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  key: const Key('open-dark-alert'),
                  onPressed: () => showAppAlert<void>(
                    context,
                    title: '暗黑弹框',
                    message: '弹框应使用暗色语义表面。',
                    actions: const [AppAlertAction(label: '知道了', result: null)],
                  ),
                  child: const Text('弹框'),
                ),
                TextButton(
                  key: const Key('open-dark-date-sheet'),
                  onPressed: () => showAppDatePicker(
                    context: context,
                    initialDate: DateTime(2026, 8, 22),
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2026, 12, 31),
                    currentDate: DateTime(2026, 8, 22),
                  ),
                  child: const Text('日期'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-dark-alert')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
      HearthioPalette.dark.paper,
    );
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-dark-date-sheet')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
      HearthioPalette.dark.paper,
    );
    final monthLabel = tester.widget<Text>(
      find.byKey(const Key('app-date-picker-month-label')),
    );
    expect(monthLabel.style?.color, HearthioPalette.dark.ink);
  });
}

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
