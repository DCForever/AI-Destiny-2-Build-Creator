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
  // Default: publish real semantics so Widgetbook exercises shared UI a11y
  // (errors usually come from ui_flutter / host icons, not Widgetbook chrome).
  // Opt-in silence: --dart-define=EXCLUDE_WIDGETBOOK_SEMANTICS=true
  const excludeSemantics = bool.fromEnvironment(
    'EXCLUDE_WIDGETBOOK_SEMANTICS',
    defaultValue: false,
  );
  runWidgetbook(excludePlatformSemantics: excludeSemantics);
}

/// Shared run path for [main] and [main_mcp] (no second driver bind).
///
/// Prefer fixing shared widgets under [destiny2_ui_flutter] rather than
/// excluding semantics here. [excludePlatformSemantics] is an opt-in escape
/// hatch for noisy Windows bridge logs while iterating.
void runWidgetbook({bool excludePlatformSemantics = false}) {
  Widget app = const Destiny2WidgetbookApp();
  if (excludePlatformSemantics) {
    app = ExcludeSemantics(child: app);
    assert(() {
      debugPrint(
        'Widgetbook: ExcludeSemantics on (EXCLUDE_WIDGETBOOK_SEMANTICS).',
      );
      return true;
    }());
  }
  runApp(app);
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
        // Phase 3: phone / tablet / desktop matrix (None = unconstrained canvas).
        ViewportAddon([
          Viewports.none,
          IosViewports.iPhone13,
          IosViewports.iPadPro11Inches,
          WindowsViewports.desktop,
        ]),
        // Off by default — inspector overlays also thrash Windows AX when on.
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
