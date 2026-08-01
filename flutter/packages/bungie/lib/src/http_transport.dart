import 'http_transport_stub.dart'
    if (dart.library.io) 'http_transport_io.dart' as impl;

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

/// Default transport: [HttpClient] on VM/native; unsupported stub on web.
///
/// Web hosts (DART-045) must inject a fetch-based [BungieHttpTransport].
BungieHttpTransport createDefaultBungieHttpTransport({Object? client}) {
  return impl.createDefaultBungieHttpTransport(client: client);
}
