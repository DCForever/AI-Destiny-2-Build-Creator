import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

/// Builds the mobile host **Matte Flap Ledger** theme stub (DART-040).
///
/// Colors from pure [FlapColorTokens.dark]. Square flat cards; bottom nav
/// uses surface + accent selection (Focus Swap shell, not dual-pane).
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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: Color(tokens.accentDim),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? accent : muted,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? accent : muted);
      }),
    ),
    dividerTheme: DividerThemeData(
      color: line,
      thickness: kFlapRuleThickness,
      space: kFlapRuleThickness,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: muted,
      textColor: onSurface,
      tileColor: surface,
      selectedTileColor: Color(tokens.accentDim),
      shape: square,
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
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(color: onSurface, fontSize: 14),
      bodySmall: TextStyle(color: muted, fontSize: 12),
    ),
  );
}
