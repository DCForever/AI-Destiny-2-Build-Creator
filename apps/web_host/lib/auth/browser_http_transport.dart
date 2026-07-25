/// Browser fetch-based [BungieHttpTransport] for Public+PKCE token exchange.
library;

import 'dart:js_interop';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:web/web.dart' as web;

/// Creates a transport using `window.fetch` (no dart:io, no client secret).
BungieHttpTransport createBrowserBungieHttpTransport() {
  return (BungieHttpRequest request) async {
    final headers = web.Headers();
    request.headers.forEach((name, value) {
      headers.set(name, value);
    });

    final init = web.RequestInit(
      method: request.method,
      headers: headers,
      body: request.body?.toJS,
    );

    final response = await web.window
        .fetch(request.uri.toString().toJS, init)
        .toDart;
    final body = await response.text().toDart;
    final headerMap = <String, String>{};
    // Headers iteration is limited; Content-Type is enough for OAuth JSON.
    final contentType = response.headers.get('content-type');
    if (contentType != null) {
      headerMap['content-type'] = contentType;
    }
    return BungieHttpResponse(
      statusCode: response.status,
      body: body,
      headers: headerMap,
    );
  };
}
