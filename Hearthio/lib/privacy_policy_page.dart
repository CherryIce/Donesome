import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'l10n/l10n.dart';
import 'theme/app_theme.dart';
import 'widgets/app_back_button.dart';
import 'widgets/app_safe_area.dart';

const privacyPolicyEnglishUrl = 'https://hearthio.app/privacy.html?lang=en';
const privacyPolicyChineseUrl = 'https://hearthio.app/privacy.html?lang=zh';

String privacyPolicyUrlForLocale(Locale locale) =>
    locale.languageCode.toLowerCase() == 'zh'
    ? privacyPolicyChineseUrl
    : privacyPolicyEnglishUrl;

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key, required this.remoteUrl});

  final String remoteUrl;

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  WebViewController? _controller;
  Uri? _policyUri;
  int _progress = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.remoteUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    _policyUri = uri;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loadError = null);
          },
          onWebResourceError: (error) {
            if ((error.isForMainFrame ?? true) && mounted) {
              setState(() => _loadError = error.description);
            }
          },
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            if (target != null &&
                target.scheme == 'https' &&
                target.host == uri.host) {
              return NavigationDecision.navigate;
            }
            if (target != null) {
              unawaited(
                launchUrl(target, mode: LaunchMode.externalApplication),
              );
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(uri);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.setBackgroundColor(context.palette.paper));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: Text(context.l10n.privacyPolicyTitle),
      actions: [
        if (_controller != null)
          IconButton(
            tooltip: context.l10n.commonRefresh,
            onPressed: () {
              setState(() => _loadError = null);
              unawaited(_controller!.reload());
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
      bottom: _controller != null && _progress < 100 && _loadError == null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(value: _progress / 100),
            )
          : null,
    ),
    body: _body(),
  );

  Widget _body() {
    if (_policyUri == null) {
      return _PrivacyFallback(
        title: context.l10n.privacyPreparingTitle,
        message: context.l10n.privacyPreparingMessage,
      );
    }
    if (_loadError != null) {
      return _PrivacyFallback(
        title: context.l10n.privacyLoadFailedTitle,
        message: context.l10n.privacyLoadFailedMessage(_loadError!),
        actionLabel: context.l10n.privacyReload,
        onAction: () {
          setState(() => _loadError = null);
          unawaited(_controller!.reload());
        },
      );
    }
    return WebViewWidget(controller: _controller!);
  }
}

class _PrivacyFallback extends StatelessWidget {
  const _PrivacyFallback({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => ListView(
    padding: appSafeScrollPadding(context, const EdgeInsets.all(24)),
    children: [
      const Icon(Icons.privacy_tip_outlined, size: 48),
      const SizedBox(height: 18),
      Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 28),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            context.l10n.privacyLocalFirstSummary,
            style: const TextStyle(height: 1.6),
          ),
        ),
      ),
      if (onAction != null) ...[
        const SizedBox(height: 16),
        FilledButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ],
  );
}
