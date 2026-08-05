import 'package:flutter/foundation.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'main.dart' as app;

/// MCP / agent entrypoint: always enables Flutter Driver, then runs Widgetbook.
///
/// Do **not** also pass `ENABLE_FLUTTER_DRIVER=true` (would double-bind).
///
/// ```text
/// flutter run -d windows -t lib/main_mcp.dart
/// ```
Future<void> main() async {
  enableFlutterDriverExtension();
  debugPrint(
    'main_mcp: Flutter Driver extension enabled (Widgetbook MCP entrypoint).',
  );
  app.runWidgetbook();
}
