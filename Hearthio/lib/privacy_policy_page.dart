import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Configure the production URL with:
/// `--dart-define=PRIVACY_POLICY_URL=https://example.com/privacy`.
const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key, this.remoteUrl = privacyPolicyUrl});

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
      ..setBackgroundColor(Colors.white)
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('隐私政策'),
      actions: [
        if (_controller != null)
          IconButton(
            tooltip: '刷新',
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
      return const _PrivacyFallback(
        title: '隐私政策页面正在准备中',
        message: '正式 HTTPS 地址接入后，这里将直接展示完整隐私政策。',
      );
    }
    if (_loadError != null) {
      return _PrivacyFallback(
        title: '暂时无法加载隐私政策',
        message: '请检查网络后重试。\n$_loadError',
        actionLabel: '重新加载',
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
    padding: const EdgeInsets.all(24),
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
      const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            '家务志无需注册。物品信息、照片、维护记录和计划默认保存在本机；只有在你主动导出、备份或分享时，相关文件才会离开 App 沙盒。',
            style: TextStyle(height: 1.6),
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
