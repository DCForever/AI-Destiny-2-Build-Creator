import 'package:flutter/foundation.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'main.dart' as host;

/// MCP / agent entrypoint: always enables Flutter Driver, then runs the host.
///
/// Use with Dart MCP `launch_app` so the agent receives a DTD URI and can
/// screenshot/tap without shell `flutter run` or manual DTD paste:
///
/// ```text
/// launch_app root=…/apps/windows_host device=windows target=lib/main_mcp.dart
/// ```
///
/// Prefer [host.main] (`lib/main.dart`) for everyday use (driver off unless
/// `ENABLE_FLUTTER_DRIVER=true`). Do not ship this entrypoint as the store
/// production main.
Future<void> main() async {
  enableFlutterDriverExtension();
  debugPrint(
    'main_mcp: Flutter Driver extension enabled (MCP entrypoint). '
    'Real keyboard typing may be emulated.',
  );
  await host.main();
}
