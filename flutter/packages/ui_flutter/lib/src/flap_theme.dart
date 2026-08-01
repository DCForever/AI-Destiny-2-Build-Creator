import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'flap_palette.dart';

/// Optional shell-specific theme slots (NavigationRail vs NavigationBar, etc.).
typedef FlapThemeCustomize = ThemeData Function(
  ThemeData theme,
  FlapColorTokens tokens,
  FlapPalette palette,
);

/// Shared Matte Flap Ledger [ThemeData] for Flutter hosts.
///
/// - Colors from pure [FlapColorTokens] (not `ColorScheme.fromSeed`).
/// - Full flap roles on [FlapPalette] extension (status lamps, element ink).
/// - Square elevation-0 cards (Board Not Cards / Square Board).
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
      titleTextStyle: TextStyle(
        color: onSurface,
        fontSize: kTypeHeadline.fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        fontFamily: kFontDisplay,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: line,
      thickness: kFlapRuleThickness,
      space: kFlapRuleThickness,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: palette.accentDim,
        foregroundColor: accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kFlapRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        side: BorderSide(color: line),
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
        borderSide: BorderSide(color: accent),
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
      contentTextStyle: TextStyle(color: onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kFlapRadius),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: _flapTextTheme(onSurface, muted),
  );

  if (customize != null) {
    theme = customize(theme, tokens, palette);
  }
  return theme;
}

TextTheme _flapTextTheme(Color onSurface, Color muted) {
  return TextTheme(
    titleLarge: TextStyle(
      color: onSurface,
      fontSize: kTypeHeadline.fontSize,
      fontWeight: FontWeight.w600,
      fontFamily: kFontDisplay,
    ),
    titleMedium: TextStyle(
      color: onSurface,
      fontSize: kTypeTitle.fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      fontFamily: kFontDisplay,
    ),
    bodyLarge: TextStyle(
      color: onSurface,
      fontSize: kTypeBody.fontSize,
      fontWeight: FontWeight.w400,
      fontFamily: kFontBody,
    ),
    bodyMedium: TextStyle(
      color: onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: kFontBody,
    ),
    bodySmall: TextStyle(
      color: muted,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: kFontBody,
    ),
    labelLarge: TextStyle(
      color: onSurface,
      fontSize: kTypeLabel.fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      fontFamily: kFontDisplay,
    ),
    labelSmall: TextStyle(
      color: muted,
      fontSize: kTypeLabel.fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      fontFamily: kFontDisplay,
    ),
  );
}
