import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

/// Windows host Matte Flap Ledger theme (shared base + NavigationRail).
///
/// Colors and [FlapPalette] come from [buildFlapThemeBase] / pure tokens.
ThemeData buildFlapTheme({Brightness brightness = Brightness.dark}) {
  return buildFlapThemeBase(
    brightness: brightness,
    customize: (theme, tokens, palette) {
      return theme.copyWith(
        // Avoid Material 3 InkSparkle shader decode failures under flutter test
        // (ink_sparkle.frag stages version mismatch on some Windows hosts).
        splashFactory: NoSplash.splashFactory,
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: palette.surface,
          indicatorColor: palette.accentDim,
          selectedIconTheme: IconThemeData(color: palette.accent),
          unselectedIconTheme: IconThemeData(color: palette.muted),
          selectedLabelTextStyle: TextStyle(color: palette.accent, fontSize: 12),
          unselectedLabelTextStyle: TextStyle(color: palette.muted, fontSize: 12),
        ),
      );
    },
  );
}
