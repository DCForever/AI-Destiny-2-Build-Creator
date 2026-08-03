import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

/// Mobile host Matte Flap Ledger theme (shared base + NavigationBar / ListTile).
///
/// Focus Swap shell — not dual-pane. Status lamps live on [FlapPalette], not
/// [ColorScheme.primary] (One Lamp rule).
ThemeData buildFlapTheme({Brightness brightness = Brightness.dark}) {
  return buildFlapThemeBase(
    brightness: brightness,
    customize: (theme, tokens, palette) {
      final square = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kFlapRadius),
        side: BorderSide(color: palette.line, width: kFlapRuleThickness),
      );
      return theme.copyWith(
        // Avoid Material 3 InkSparkle shader decode failures under flutter test
        // (ink_sparkle.frag stages version mismatch on some Windows hosts).
        splashFactory: NoSplash.splashFactory,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: palette.surface,
          indicatorColor: palette.accentDim,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? palette.accent : palette.muted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? palette.accent : palette.muted,
            );
          }),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: palette.muted,
          textColor: palette.foreground,
          tileColor: palette.surface,
          selectedTileColor: palette.accentDim,
          shape: square,
        ),
      );
    },
  );
}
