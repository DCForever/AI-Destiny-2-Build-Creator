/// Browser fetch for prebuilt entity bundles (DART-044).
///
/// Import only from client entry / browser code — not from VM unit tests.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Same-origin GET returning response text (throws on non-2xx).
Future<String> fetchEntityBundleText(String url) async {
  final response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError(
      'Failed to fetch entity bundle: HTTP ${response.status} for $url',
    );
  }
  final jsText = await response.text().toDart;
  return jsText.toDart;
}
