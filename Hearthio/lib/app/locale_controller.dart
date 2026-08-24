import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguageMode { system, simplifiedChinese, english }

class AppLocaleController extends ChangeNotifier {
  AppLocaleController({AppLanguageMode initialMode = AppLanguageMode.system})
    : _mode = initialMode;

  static const preferenceKey = 'app_language_mode';

  AppLanguageMode _mode;
  AppLanguageMode get mode => _mode;

  Locale? get locale => switch (_mode) {
    AppLanguageMode.system => null,
    AppLanguageMode.simplifiedChinese => const Locale('zh'),
    AppLanguageMode.english => const Locale('en'),
  };

  static Future<AppLanguageMode> readSavedMode() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(preferenceKey);
    final matching = AppLanguageMode.values.where((mode) => mode.name == saved);
    return matching.isEmpty ? AppLanguageMode.system : matching.first;
  }

  Future<void> load() async {
    final next = await readSavedMode();
    if (next == _mode) return;
    _mode = next;
    notifyListeners();
  }

  Future<void> setMode(AppLanguageMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(preferenceKey, mode.name);
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLocaleScope>()?.notifier;

  static AppLocaleController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No AppLocaleScope found in context.');
    return controller!;
  }
}

Locale resolveSupportedAppLocale(Locale? preferredLocale) {
  final preferred = preferredLocale ?? PlatformDispatcher.instance.locale;
  return Locale(preferred.languageCode.toLowerCase() == 'zh' ? 'zh' : 'en');
}

Locale resolveAppLocaleForMode(AppLanguageMode mode, {Locale? systemLocale}) =>
    switch (mode) {
      AppLanguageMode.system => resolveSupportedAppLocale(systemLocale),
      AppLanguageMode.simplifiedChinese => const Locale('zh'),
      AppLanguageMode.english => const Locale('en'),
    };
