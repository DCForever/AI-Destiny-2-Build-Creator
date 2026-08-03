import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';

/// Widget-test theme without Material 3 InkSparkle (shader decode flake on
/// some Windows hosts: ink_sparkle.frag stages version mismatch).
ThemeData testMaterialTheme() => buildFlapTheme().copyWith(
      splashFactory: NoSplash.splashFactory,
    );
