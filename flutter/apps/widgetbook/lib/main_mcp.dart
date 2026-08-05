import 'package:flutter/foundation.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'main.dart' as app;

/// MCP / agent entrypoint: always enables Flutter Driver, then runs Widgetbook.
///
/// ```text
/// launch_app root=…/apps/widgetbook device=windows target=lib/main_mcp.dart
/// ```
Future<void> main() async {
  enableFlutterDriverExtension();
  debugPrint(
    'main_mcp: Flutter Driver extension enabled (Widgetbook MCP entrypoint).',
  );
  app.main();
}
