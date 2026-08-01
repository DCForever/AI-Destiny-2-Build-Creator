import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'main.dart' as app;

/// Debug entrypoint for Dart MCP / flutter_driver automation.
///
/// Enables the driver extension **before** any binding is initialized, then
/// runs the normal app entrypoint.
void main() {
  // Must run first — before WidgetsFlutterBinding.ensureInitialized().
  enableFlutterDriverExtension();
  // app.main is async; fire-and-forget is correct for Flutter entrypoints.
  // ignore: discarded_futures
  app.main();
}
