import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'http_transport.dart';

/// Default transport using [HttpClient] with UTF-8 body decode (VM / native).
///
/// Prefer reusing a single [HttpClient] for long-lived host processes.
BungieHttpTransport createDefaultBungieHttpTransport({Object? client}) {
  final http = client is HttpClient ? client : HttpClient();
  // Avoid hanging OAuth / API calls forever (UI would stay on "Signing in…").
  http.connectionTimeout = const Duration(seconds: 30);
  http.idleTimeout = const Duration(seconds: 30);
  return (BungieHttpRequest request) async {
    final ioRequest = await http.openUrl(request.method, request.uri);
    ioRequest.followRedirects = true;
    request.headers.forEach(ioRequest.headers.set);
    if (request.body != null) {
      final bytes = utf8.encode(request.body!);
      ioRequest.contentLength = bytes.length;
      ioRequest.add(bytes);
    }
    final HttpClientResponse response;
    try {
      response = await ioRequest.close().timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw TimeoutException(
        'Bungie HTTP ${request.method} ${request.uri} timed out',
      );
    }
    final builder = BytesBuilder(copy: false);
    try {
      await for (final chunk in response.timeout(const Duration(seconds: 45))) {
        builder.add(chunk);
      }
    } on TimeoutException {
      throw TimeoutException(
        'Bungie HTTP body ${request.method} ${request.uri} timed out',
      );
    }
    final bytes = Uint8List.fromList(builder.takeBytes());
    final headerMap = <String, String>{};
    response.headers.forEach((name, values) {
      if (values.isNotEmpty) {
        headerMap[name.toLowerCase()] = values.join(',');
      }
    });
    return BungieHttpResponse(
      statusCode: response.statusCode,
      body: utf8.decode(bytes),
      headers: headerMap,
    );
  };
}
