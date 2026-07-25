import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Outgoing Platform request (absolute URI + headers + optional body).
class BungieHttpRequest {
  const BungieHttpRequest({
    required this.method,
    required this.uri,
    required this.headers,
    this.body,
  });

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
}

/// Raw HTTP response used by [BungieHttpTransport].
class BungieHttpResponse {
  const BungieHttpResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final String body;

  /// Response headers (keys may be lowercased by default transport).
  final Map<String, String> headers;
}

/// Injectable HTTP function for tests and hosts.
typedef BungieHttpTransport = Future<BungieHttpResponse> Function(
  BungieHttpRequest request,
);

/// Default transport using [HttpClient] with UTF-8 body decode.
///
/// Prefer reusing a single [HttpClient] for long-lived host processes.
BungieHttpTransport createDefaultBungieHttpTransport({HttpClient? client}) {
  final http = client ?? HttpClient();
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
