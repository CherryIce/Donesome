import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/app/locale_controller.dart';
import 'package:hearthio/l10n/app_localizations.dart';
import 'package:hearthio/l10n/catalog_l10n.dart';
import 'package:hearthio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('English and Simplified Chinese ARB files keep the same contract', () {
    final english =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    final chinese =
        jsonDecode(File('lib/l10n/app_zh.arb').readAsStringSync())
            as Map<String, dynamic>;

    expect(english.keys.toSet(), chinese.keys.toSet());
  });

  test('locale controller persists the explicit language choice', () async {
    final controller = AppLocaleController();
    await controller.setMode(AppLanguageMode.english);

    final restored = AppLocaleController();
    await restored.load();

    expect(restored.mode, AppLanguageMode.english);
    expect(restored.locale, const Locale('en'));
    expect(
      resolveSupportedAppLocale(const Locale('zh', 'HK')),
      const Locale('zh'),
    );
    expect(resolveSupportedAppLocale(const Locale('fr')), const Locale('en'));
  });

  test('built-in categories and default space names localize both ways', () {
    final english = lookupAppLocalizations(const Locale('en'));
    final chinese = lookupAppLocalizations(const Locale('zh'));
    const defaultKitchen = CareSpace(
      id: 'kitchen',
      type: '厨房',
      name: 'Kitchen',
    );
    const customKitchen = CareSpace(
      id: 'pantry',
      type: '厨房',
      name: 'Dry pantry',
    );

    expect(chinese.itemCategoryLabel('Filters & consumables'), '滤芯与耗材');
    expect(english.itemCategoryLabel('滤芯与耗材'), 'Filters & consumables');
    expect(chinese.itemCategoryLabel('My category'), 'My category');
    expect(chinese.spaceNameLabel(defaultKitchen), '厨房');
    expect(english.spaceNameLabel(defaultKitchen), 'Kitchen');
    expect(chinese.spaceNameLabel(customKitchen), 'Dry pantry');
  });

  testWidgets('onboarding localizes every page in English', (tester) async {
    await _pumpOnboarding(tester, const Locale('en'));

    expect(find.text('Build a home inventory'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Keep the details with photos'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Stay on schedule'), findsOneWidget);
    expect(find.text('Start organizing'), findsOneWidget);
  });

  testWidgets('onboarding localizes every page in Simplified Chinese', (
    tester,
  ) async {
    await _pumpOnboarding(tester, const Locale('zh'));

    expect(find.text('先给家里的物品建档'), findsOneWidget);
    expect(find.text('跳过'), findsOneWidget);
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('拍下凭证，留住细节'), findsOneWidget);
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('日历提醒，按时照料'), findsOneWidget);
    expect(find.text('开始整理'), findsOneWidget);
  });

  testWidgets('changing the app language rebuilds onboarding immediately', (
    tester,
  ) async {
    final controller = AppLocaleController(
      initialMode: AppLanguageMode.english,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(HearthioApp(localeController: controller));
    await tester.pumpAndSettle();
    expect(find.text('Build a home inventory'), findsOneWidget);

    await controller.setMode(AppLanguageMode.simplifiedChinese);
    await tester.pumpAndSettle();
    expect(find.text('先给家里的物品建档'), findsOneWidget);
    expect(find.text('Build a home inventory'), findsNothing);
  });
}

Future<void> _pumpOnboarding(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: OnboardingPage(onFinished: () async {}),
    ),
  );
  await tester.pumpAndSettle();
}
