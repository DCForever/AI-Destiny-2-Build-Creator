/// Client entrypoint for the Jaspr web host (DART-042).
///
/// Compiled to JavaScript and executed in the browser. No Next.js, no secrets.
library;

import 'package:jaspr/client.dart';

import 'app.dart';

void main() {
  runApp(const App());
}
