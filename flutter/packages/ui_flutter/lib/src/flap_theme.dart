import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'flap_palette.dart';
import 'neon_fonts.dart';

/// Optional shell-specific theme slots (NavigationRail vs NavigationBar, etc.).
typedef FlapThemeCustomize = ThemeData Function(
  ThemeData theme,
  FlapColorTokens tokens,
  FlapPalette palette,
);

/// Shared Neon Network [ThemeData] for Flutter hosts (Flap board structure).
///
/// - Colors from pure [FlapColorTokens] / Neon Network (not `ColorScheme.fromSeed`).
/// - Full roles on [FlapPalette] extension (status lamps, element ink).
/// - Orbitron · Inter · JetBrains Mono via [google_fonts] ([neonTextTheme]).
/// - Square elevation-0 cards; grey hairline structure; cyan signal for focus/CTA.
ThemeData buildFlapThemeBase({
  Brightness brightness = Brightness.dark,
  FlapThemeCustomize? customize,
}) {
  final tokens =
      brightness == Brightness.dark ? FlapColorTokens.dark : FlapColorTokens.light;
  final palette = FlapPalette.fromTokens(tokens);

  final background = palette.background;
  final surface = palette.surface;
  final surfaceRaised = palette.surfaceRaised;
  final onSurface = palette.foreground;
  final muted = palette.muted;
  final accent = palette.accent;
  final danger = palette.danger;
  final line = palette.line;
  final textTheme = neonTextTheme(onSurface: onSurface, muted: muted);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: background,
    secondary: palette.accentStrong,
    onSecondary: background,
    error: danger,
    onError: onSurface,
    surface: surface,
    onSurface: onSurface,
  );

  final square = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kFlapRadius),
    side: BorderSide(color: line, width: kFlapRuleThickness),
  );

  var theme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: neonBodyFontFamily,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: surface,
    dividerColor: line,
    extensions: <ThemeExtension<dynamic>>[palette],
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: square,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: surface,
      foregroundColor: onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: neonDisplay(
        color: onSurface,
        fontSize: kTypeHeadline.fontSize,
        letterSpacing: kTypeHeadline.letterSpacing,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: line,
      thickness: kFlapRuleThickness,
      space: kFlapRuleThickness,
    ),
    // Primary CTA: soft cyan wash + solid cyan type (≤2 strong cyan hits / region).
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: palette.accentDim,
        foregroundColor: accent,
        minimumSize: const Size(0, kControlHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kFlapRadius),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: accent,
        foregroundColor: background,
        minimumSize: const Size(0, kControlHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kFlapRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        side: BorderSide(color: line),
        minimumSize: const Size(0, kControlHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kFlapRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kFlapRadius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kFlapRadius),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kFlapRadius),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kFlapRadius),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      elevation: 0,
      pressElevation: 0,
      backgroundColor: surfaceRaised,
      selectedColor: palette.accentDim,
      labelStyle: TextStyle(color: onSurface, fontSize: 12),
      side: BorderSide(color: line),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kFlapRadius),
      ),
    ),
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: square,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceRaised,
      contentTextStyle: neonBody(color: onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kFlapRadius),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: textTheme,
    primaryTextTheme: textTheme,
  );

  if (customize != null) {
    theme = customize(theme, tokens, palette);
  }
  return theme;
}
