import 'dart:async';

import 'package:flutter/services.dart';

/// Cross-platform entry point for STMini.
///
/// The plugin is deliberately limited to generic Mini-program capabilities:
/// verified ZIP packages, `mini://` opening, local package reuse, native
/// loading UI, lifecycle events and the framework Mini APIs. Business APIs
/// such as accounts, trading and authorisation belong to the embedding app.
class StminiFlutter {
  StminiFlutter._();

  static const MethodChannel _methods = MethodChannel('stmini_flutter/methods');
  static const EventChannel _events = EventChannel('stmini_flutter/events');

  /// Native lifecycle/install/open diagnostic events.
  static Stream<StminiEvent> get events => _events
      .receiveBroadcastStream()
      .where((value) => value is Map)
      .map(
        (value) => StminiEvent.fromMap(Map<String, dynamic>.from(value as Map)),
      );

  /// Configures the native STMini host once before opening a Mini.
  ///
  /// [loadingImage] is an optional image name from the host application's
  /// resources. If omitted STMini uses its packaged fallback loading UI.
  ///
  /// [bridgeContext] is optional host-owned, JSON-compatible context for
  /// generic H5 bridge APIs. A host may provide `packageName`, `userInfo`,
  /// `config`, and an `authStorageKey` when its Mini persists a JSON auth
  /// snapshot through the storage bridge. `packageName` defaults to an empty
  /// string; STMini never embeds a business package identifier.
  static Future<void> initialize({
    String? loadingImage,
    Map<String, dynamic>? bridgeContext,
  }) {
    return _methods.invokeMethod<void>('initialize', {
      if (loadingImage != null && loadingImage.isNotEmpty)
        'loadingImage': loadingImage,
      if (bridgeContext != null) 'bridgeContext': bridgeContext,
    });
  }

  /// Opens an online Mini using the shared `mini://<miniId>` contract.
  ///
  /// The link may carry `downloadUrl`, version and display parameters. The
  /// native STMini container owns download, verification, atomic installation,
  /// local package reuse and its loading animation.
  static Future<void> openMini(String link) {
    return _methods.invokeMethod<void>('openMini', {'link': link});
  }

  /// Presents an external HTTP(S) page in STMini's reusable native H5
  /// container. The page is independent of any Mini ZIP package.
  ///
  /// [showNavigationBar] defaults to true so the host always provides a
  /// native back affordance. Set it to false only when the page owns its own
  /// complete navigation and close behaviour.
  static Future<void> openWeb(
    String url, {
    String? title,
    bool showNavigationBar = true,
  }) {
    return _methods.invokeMethod<void>('openWeb', {
      'url': url,
      if (title != null && title.isNotEmpty) 'title': title,
      'showNavigationBar': showNavigationBar,
    });
  }

  /// Dismisses the currently presented Mini container, if any.
  static Future<void> closeMini() => _methods.invokeMethod<void>('closeMini');

  /// Returns only fully verified and runnable local Mini packages.
  static Future<List<StminiPackage>> installedPackages() async {
    final packages =
        await _methods.invokeListMethod<Map>('installedPackages') ?? const [];
    return packages
        .map((value) => StminiPackage.fromMap(Map<String, dynamic>.from(value)))
        .toList(growable: false);
  }

  /// Returns whether the iOS host module is available.
  static Future<bool> get isAvailable async =>
      (await _methods.invokeMethod<bool>('isAvailable')) ?? false;
}

class StminiEvent {
  const StminiEvent({required this.name, required this.payload});

  factory StminiEvent.fromMap(Map<String, dynamic> value) => StminiEvent(
    name: value['name'] as String? ?? 'unknown',
    payload: Map<String, dynamic>.from(value['payload'] as Map? ?? const {}),
  );

  final String name;
  final Map<String, dynamic> payload;
}

class StminiPackage {
  const StminiPackage({
    required this.miniId,
    required this.miniName,
    required this.iconUrl,
    required this.launchLink,
  });

  factory StminiPackage.fromMap(Map<String, dynamic> value) => StminiPackage(
    miniId: value['miniId'] as String? ?? '',
    miniName: value['miniName'] as String? ?? '',
    iconUrl: value['iconUrl'] as String? ?? '',
    launchLink: value['launchLink'] as String? ?? '',
  );

  final String miniId;
  final String miniName;
  final String iconUrl;
  final String launchLink;
}
