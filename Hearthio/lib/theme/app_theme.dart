import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class HearthioPalette extends ThemeExtension<HearthioPalette> {
  const HearthioPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.canvas,
    required this.paper,
    required this.raised,
    required this.mist,
    required this.softSurface,
    required this.ink,
    required this.muted,
    required this.subtle,
    required this.border,
    required this.divider,
    required this.disabled,
    required this.handle,
    required this.success,
    required this.successStrong,
    required this.successSurface,
    required this.action,
    required this.warning,
    required this.warningStrong,
    required this.warningSurface,
    required this.danger,
    required this.dangerStrong,
    required this.dangerSurface,
    required this.deferred,
    required this.scrim,
    required this.shadow,
  });

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color canvas;
  final Color paper;
  final Color raised;
  final Color mist;
  final Color softSurface;
  final Color ink;
  final Color muted;
  final Color subtle;
  final Color border;
  final Color divider;
  final Color disabled;
  final Color handle;
  final Color success;
  final Color successStrong;
  final Color successSurface;
  final Color action;
  final Color warning;
  final Color warningStrong;
  final Color warningSurface;
  final Color danger;
  final Color dangerStrong;
  final Color dangerSurface;
  final Color deferred;
  final Color scrim;
  final Color shadow;

  bool get isDark => brightness == Brightness.dark;

  static const light = HearthioPalette(
    brightness: Brightness.light,
    primary: Color(0xFF31584B),
    onPrimary: Colors.white,
    accent: Color(0xFFE59A72),
    canvas: Color(0xFFF7F8F3),
    paper: Color(0xFFFFFEFA),
    raised: Colors.white,
    mist: Color(0xFFEAF1E9),
    softSurface: Color(0xFFF2F4ED),
    ink: Color(0xFF263630),
    muted: Color(0xFF72817A),
    subtle: Color(0xFF8A9992),
    border: Color(0xFFE2E9E2),
    divider: Color(0xFFE8EDE7),
    disabled: Color(0xFFB7C0BA),
    handle: Color(0xFFC9CEC9),
    success: Color(0xFF3A7D70),
    successStrong: Color(0xFF176B57),
    successSurface: Color(0xFFF0FAF3),
    action: Color(0xFF137B67),
    warning: Color(0xFFC36F2D),
    warningStrong: Color(0xFF8A542E),
    warningSurface: Color(0xFFFFF0E5),
    danger: Color(0xFFB64B43),
    dangerStrong: Color(0xFFB42318),
    dangerSurface: Color(0xFFFFF2F1),
    deferred: Color(0xFF725E91),
    scrim: Color(0x990F1714),
    shadow: Color(0x24000000),
  );

  static const dark = HearthioPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF8EC7B1),
    onPrimary: Color(0xFF10251D),
    accent: Color(0xFFF0B08A),
    canvas: Color(0xFF111714),
    paper: Color(0xFF18211D),
    raised: Color(0xFF202B26),
    mist: Color(0xFF243A32),
    softSurface: Color(0xFF202A25),
    ink: Color(0xFFE8F0EB),
    muted: Color(0xFFA8B7AF),
    subtle: Color(0xFF87968E),
    border: Color(0xFF34463E),
    divider: Color(0xFF2B3933),
    disabled: Color(0xFF65736C),
    handle: Color(0xFF526159),
    success: Color(0xFF79C8AD),
    successStrong: Color(0xFF93D9C1),
    successSurface: Color(0xFF1E342B),
    action: Color(0xFF93D9C1),
    warning: Color(0xFFF2B174),
    warningStrong: Color(0xFFFFC99F),
    warningSurface: Color(0xFF3A291F),
    danger: Color(0xFFFF8A80),
    dangerStrong: Color(0xFFFFB4AB),
    dangerSurface: Color(0xFF3A2020),
    deferred: Color(0xFFC7B2E4),
    scrim: Color(0xB3000000),
    shadow: Color(0x66000000),
  );

  @override
  HearthioPalette copyWith({
    Brightness? brightness,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? canvas,
    Color? paper,
    Color? raised,
    Color? mist,
    Color? softSurface,
    Color? ink,
    Color? muted,
    Color? subtle,
    Color? border,
    Color? divider,
    Color? disabled,
    Color? handle,
    Color? success,
    Color? successStrong,
    Color? successSurface,
    Color? action,
    Color? warning,
    Color? warningStrong,
    Color? warningSurface,
    Color? danger,
    Color? dangerStrong,
    Color? dangerSurface,
    Color? deferred,
    Color? scrim,
    Color? shadow,
  }) => HearthioPalette(
    brightness: brightness ?? this.brightness,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    accent: accent ?? this.accent,
    canvas: canvas ?? this.canvas,
    paper: paper ?? this.paper,
    raised: raised ?? this.raised,
    mist: mist ?? this.mist,
    softSurface: softSurface ?? this.softSurface,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    subtle: subtle ?? this.subtle,
    border: border ?? this.border,
    divider: divider ?? this.divider,
    disabled: disabled ?? this.disabled,
    handle: handle ?? this.handle,
    success: success ?? this.success,
    successStrong: successStrong ?? this.successStrong,
    successSurface: successSurface ?? this.successSurface,
    action: action ?? this.action,
    warning: warning ?? this.warning,
    warningStrong: warningStrong ?? this.warningStrong,
    warningSurface: warningSurface ?? this.warningSurface,
    danger: danger ?? this.danger,
    dangerStrong: dangerStrong ?? this.dangerStrong,
    dangerSurface: dangerSurface ?? this.dangerSurface,
    deferred: deferred ?? this.deferred,
    scrim: scrim ?? this.scrim,
    shadow: shadow ?? this.shadow,
  );

  @override
  HearthioPalette lerp(HearthioPalette? other, double t) {
    if (other == null) return this;
    return HearthioPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      mist: Color.lerp(mist, other.mist, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      handle: Color.lerp(handle, other.handle, t)!,
      success: Color.lerp(success, other.success, t)!,
      successStrong: Color.lerp(successStrong, other.successStrong, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      action: Color.lerp(action, other.action, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningStrong: Color.lerp(warningStrong, other.warningStrong, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerStrong: Color.lerp(dangerStrong, other.dangerStrong, t)!,
      dangerSurface: Color.lerp(dangerSurface, other.dangerSurface, t)!,
      deferred: Color.lerp(deferred, other.deferred, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension HearthioThemeContext on BuildContext {
  HearthioPalette get palette =>
      Theme.of(this).extension<HearthioPalette>() ?? HearthioPalette.light;
}

abstract final class HearthioTheme {
  static final ThemeData light = _build(HearthioPalette.light);
  static final ThemeData dark = _build(HearthioPalette.dark);

  static ThemeData _build(HearthioPalette palette) {
    final brightness = palette.brightness;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    );
    final colorScheme = baseScheme.copyWith(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.success,
      onSecondary: palette.onPrimary,
      tertiary: palette.accent,
      surface: palette.paper,
      onSurface: palette.ink,
      onSurfaceVariant: palette.muted,
      outline: palette.border,
      outlineVariant: palette.divider,
      error: palette.danger,
      onError: brightness == Brightness.dark
          ? const Color(0xFF3B0808)
          : Colors.white,
      surfaceContainerLowest: palette.canvas,
      surfaceContainerLow: palette.softSurface,
      surfaceContainer: palette.mist,
      surfaceContainerHigh: palette.raised,
      surfaceContainerHighest: palette.raised,
    );
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,
      cardColor: palette.paper,
      dividerColor: palette.divider,
      disabledColor: palette.disabled,
      shadowColor: palette.shadow,
      splashColor: palette.primary.withValues(alpha: 0.10),
      highlightColor: palette.primary.withValues(alpha: 0.07),
      textTheme: base.textTheme.apply(
        bodyColor: palette.ink,
        displayColor: palette.ink,
      ),
      iconTheme: IconThemeData(color: palette.ink),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: palette.canvas,
        foregroundColor: palette.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: palette.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: palette.ink),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: const CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: palette.muted),
        hintStyle: TextStyle(color: palette.subtle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          disabledBackgroundColor: palette.disabled.withValues(alpha: 0.35),
          disabledForegroundColor: palette.muted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.primary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.paper,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: palette.ink,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: palette.muted,
          height: 1.45,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.paper,
        modalBackgroundColor: palette.paper,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: palette.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.raised,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: palette.ink),
      ),
      dividerTheme: DividerThemeData(color: palette.divider),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: palette.primary,
        scaffoldBackgroundColor: palette.canvas,
        barBackgroundColor: palette.paper,
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }
}
