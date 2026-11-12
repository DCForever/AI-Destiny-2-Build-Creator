import 'package:flutter/material.dart';

/// Cycles [ThemeMode]: system → dark (Neutral charcoal) → light (Neutral) → system.
ThemeMode nextFlapThemeMode(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return ThemeMode.dark;
    case ThemeMode.dark:
      return ThemeMode.light;
    case ThemeMode.light:
      return ThemeMode.system;
  }
}

/// Short label for Settings / chrome.
String flapThemeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return 'System';
    case ThemeMode.dark:
      return 'Neutral dark';
    case ThemeMode.light:
      return 'Neutral light';
  }
}

/// Icon for the current preference.
IconData flapThemeModeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return Icons.brightness_auto;
    case ThemeMode.dark:
      return Icons.dark_mode_outlined;
    case ThemeMode.light:
      return Icons.light_mode_outlined;
  }
}

/// Settings-row control: shows active face and advances on press.
class FlapThemeModeTile extends StatelessWidget {
  const FlapThemeModeTile({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const Key('flap_theme_mode_tile'),
      leading: Icon(flapThemeModeIcon(mode)),
      title: const Text('Appearance'),
      subtitle: Text(
        '${flapThemeModeLabel(mode)} · dark=Neutral charcoal, light=Neutral stage',
        key: const Key('flap_theme_mode_label'),
      ),
      trailing: OutlinedButton(
        key: const Key('flap_theme_mode_cycle'),
        onPressed: () => onChanged(nextFlapThemeMode(mode)),
        child: Text(flapThemeModeLabel(mode)),
      ),
    );
  }
}
