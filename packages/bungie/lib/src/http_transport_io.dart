import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'http_transport.dart';

/// Default transport using [HttpClient] with UTF-8 body decode (VM / native).
///
/// Prefer reusing a single [HttpClient] for long-lived host processes.
BungieHttpTransport createDefaultBungieHttpTransport({Object? client}) {
  final http = client is HttpClient ? client : HttpClient();
  return (BungieHttpRequest request) async {
    final ioRequest = await http.openUrl(request.method, request.uri);
    request.headers.forEach(ioRequest.headers.set);
    if (request.body != null) {
      final bytes = utf8.encode(request.body!);
      ioRequest.contentLength = bytes.length;
      ioRequest.add(bytes);
    }
    final response = await ioRequest.close();
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
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
