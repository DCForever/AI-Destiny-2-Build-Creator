import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

/// Builds the Windows host **Matte Flap Ledger** theme stub (DART-029).
///
/// - Colors from pure [FlapColorTokens.dark] (not `ColorScheme.fromSeed`).
/// - **No Material-card default:** elevation 0, square shape (radius 0), surface
///   fill — existing `Card` widgets inherit matte plates without a full rewrite.
/// - Custom fonts are optional; family names are set when useful, with system
///   fallbacks if binaries are not bundled.
ThemeData buildFlapTheme({Brightness brightness = Brightness.dark}) {
  final tokens =
      brightness == Brightness.dark ? FlapColorTokens.dark : FlapColorTokens.light;

  final background = Color(tokens.background);
  final surface = Color(tokens.surface);
  final surfaceRaised = Color(tokens.surfaceRaised);
  final onSurface = Color(tokens.foreground);
  final muted = Color(tokens.muted);
  final accent = Color(tokens.accent);
  final danger = Color(tokens.danger);
  final line = Color(tokens.line);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: background,
    secondary: Color(tokens.accentStrong),
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

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: surface,
    dividerColor: line,
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
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surface,
      indicatorColor: Color(tokens.accentDim),
      selectedIconTheme: IconThemeData(color: accent),
      unselectedIconTheme: IconThemeData(color: muted),
      selectedLabelTextStyle: TextStyle(color: accent, fontSize: 12),
      unselectedLabelTextStyle: TextStyle(color: muted, fontSize: 12),
    ),
    dividerTheme: DividerThemeData(
      color: line,
      thickness: kFlapRuleThickness,
      space: kFlapRuleThickness,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Color(tokens.accentDim),
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
      selectedColor: Color(tokens.accentDim),
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
}

TextTheme _flapTextTheme(Color onSurface, Color muted) {
  return TextTheme(
    titleLarge: TextStyle(
      color: onSurface,
      fontSize: kTypeHeadline.fontSize,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: onSurface,
      fontSize: kTypeTitle.fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    bodyLarge: TextStyle(
      color: onSurface,
      fontSize: kTypeBody.fontSize,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      color: onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      color: muted,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      color: onSurface,
      fontSize: kTypeLabel.fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    ),
  );
}
