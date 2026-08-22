import 'package:flutter/widgets.dart';

/// Keeps scrollable content above system gesture areas without shortening the
/// scrollable itself. The page background can continue to the screen edge,
/// while the final control can still be scrolled fully into view.
EdgeInsets appSafeScrollPadding(
  BuildContext context,
  EdgeInsets padding, {
  bool includeHorizontalInsets = true,
}) {
  final safeInsets = MediaQuery.viewPaddingOf(context);
  return EdgeInsets.fromLTRB(
    padding.left + (includeHorizontalInsets ? safeInsets.left : 0),
    padding.top,
    padding.right + (includeHorizontalInsets ? safeInsets.right : 0),
    padding.bottom + safeInsets.bottom,
  );
}
