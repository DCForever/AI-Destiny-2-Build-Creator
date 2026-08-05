import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'main.directories.g.dart';

/// Everyday entry: driver off unless `ENABLE_FLUTTER_DRIVER=true`.
/// Prefer [main_mcp.dart] for Dart MCP screenshots (enables driver once).
const bool _enableFlutterDriver =
    bool.fromEnvironment('ENABLE_FLUTTER_DRIVER', defaultValue: false);

void main() {
  if (_enableFlutterDriver) {
    enableFlutterDriverExtension();
    debugPrint(
      'Flutter Driver extension enabled (ENABLE_FLUTTER_DRIVER).',
    );
  }
  runWidgetbook();
}

/// Shared run path for [main] and [main_mcp] (no second driver bind).
void runWidgetbook() {
  runApp(const Destiny2WidgetbookApp());
}

@widgetbook.App()
class Destiny2WidgetbookApp extends StatelessWidget {
  const Destiny2WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = buildFlapThemeBase(brightness: Brightness.dark);
    final light = buildFlapThemeBase(brightness: Brightness.light);

    return Widgetbook.material(
      directories: directories,
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Flap Dark', data: dark),
            WidgetbookTheme(name: 'Flap Light', data: light),
          ],
        ),
        InspectorAddon(),
        AlignmentAddon(initialAlignment: Alignment.center),
      ],
      // Light app chrome so the Flap theme addon owns the preview surface.
      lightTheme: light,
      darkTheme: dark,
      themeMode: ThemeMode.dark,
    );
  }
}
