import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:hearthio/feature_guide_page.dart';
import 'package:hearthio/l10n/app_localizations.dart';
import 'package:hearthio/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _GuidePreviewSequence());
}

class _GuidePreviewSequence extends StatefulWidget {
  const _GuidePreviewSequence();

  @override
  State<_GuidePreviewSequence> createState() => _GuidePreviewSequenceState();
}

class _GuidePreviewSequenceState extends State<_GuidePreviewSequence> {
  static const _forcedLanguage = String.fromEnvironment(
    'GUIDE_PREVIEW_LANGUAGE',
  );

  Timer? _timer;
  bool _showEnglish = _forcedLanguage == 'en';

  @override
  void initState() {
    super.initState();
    if (_forcedLanguage.isNotEmpty) return;
    _timer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _showEnglish = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = _showEnglish ? 'en' : 'zh';
    final topic = _showEnglish
        ? FeatureGuideTopic.historyReport
        : FeatureGuideTopic.carePlan;
    return MaterialApp(
      key: ValueKey(language),
      debugShowCheckedModeBanner: false,
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: HearthioTheme.light,
      home: FeatureGuidePage(topic: topic),
    );
  }
}
