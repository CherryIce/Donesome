import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'l10n/l10n.dart';
import 'theme/app_theme.dart';
import 'widgets/app_back_button.dart';

enum FeatureGuideTopic { itemProfile, carePlan, completeCare, historyReport }

String featureGuideAssetFor(FeatureGuideTopic topic, Locale locale) {
  final language = locale.languageCode == 'zh' ? 'zh' : 'en';
  final slug = switch (topic) {
    FeatureGuideTopic.itemProfile => 'item-profile',
    FeatureGuideTopic.carePlan => 'care-plan',
    FeatureGuideTopic.completeCare => 'complete-care',
    FeatureGuideTopic.historyReport => 'history-report',
  };
  return 'assets/guides/$slug.$language.html';
}

class FeatureGuidePage extends StatefulWidget {
  const FeatureGuidePage({super.key, required this.topic});

  final FeatureGuideTopic topic;

  @override
  State<FeatureGuidePage> createState() => _FeatureGuidePageState();
}

class _FeatureGuidePageState extends State<FeatureGuidePage> {
  late final WebViewController _controller;
  String? _asset;
  Object? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if ((error.isForMainFrame ?? true) && mounted) {
              setState(() {
                _loading = false;
                _loadError = error;
              });
            }
          },
          onNavigationRequest: (request) {
            final scheme = Uri.tryParse(request.url)?.scheme;
            return scheme == 'file' || scheme == 'about' || scheme == 'data'
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_controller.setBackgroundColor(context.palette.canvas));
    final asset = featureGuideAssetFor(
      widget.topic,
      Localizations.localeOf(context),
    );
    if (_asset == asset) return;
    _asset = asset;
    _loadError = null;
    _loading = true;
    unawaited(_load(asset));
  }

  Future<void> _load(String asset) async {
    try {
      await _controller.loadFlutterAsset(asset);
    } catch (error) {
      if (mounted && _asset == asset) {
        setState(() {
          _loading = false;
          _loadError = error;
        });
      }
    }
  }

  String _title(BuildContext context) => switch (widget.topic) {
    FeatureGuideTopic.itemProfile => context.l10n.featureIntroArchiveTitle,
    FeatureGuideTopic.carePlan => context.l10n.featureIntroPlanTitle,
    FeatureGuideTopic.completeCare => context.l10n.featureIntroCompleteTitle,
    FeatureGuideTopic.historyReport => context.l10n.featureIntroReviewTitle,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(_title(context)),
      ),
    ),
    body: _loadError == null
        ? Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          )
        : _FeatureGuideError(onRetry: () => _retry()),
  );

  Future<void> _retry() async {
    final asset = _asset;
    if (asset == null) return;
    setState(() {
      _loadError = null;
      _loading = true;
    });
    await _load(asset);
  }
}

class _FeatureGuideError extends StatelessWidget {
  const _FeatureGuideError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: context.palette.muted,
            size: 44,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.featureGuideLoadFailedTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.palette.ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.featureGuideLoadFailedBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.l10n.featureGuideRetry),
          ),
        ],
      ),
    ),
  );
}
