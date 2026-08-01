import 'dart:convert';

import 'bungie_envelope.dart';
import 'bungie_errors.dart';
import 'http_transport.dart';
import 'rate_limit.dart';

/// Default Bungie Platform base (no trailing slash).
final Uri kBungiePlatformBaseUrl = Uri.parse('https://www.bungie.net/Platform');

/// Shared Bungie Platform HTTP client (DART-021).
///
/// Host injects the **public** API key only. Never pass `CLIENT_SECRET`.
/// Tokens are runtime arguments — this package does not store secrets.
class BungieHttpClient {
  BungieHttpClient({
    required String apiKey,
    Uri? baseUrl,
    BungieHttpTransport? transport,
    this.onRateLimit,
    this.defaultAccessToken,
  })  : apiKey = _requireApiKey(apiKey),
        baseUrl = _normalizeBase(baseUrl ?? kBungiePlatformBaseUrl),
        transport = transport ?? createDefaultBungieHttpTransport();

  /// Public Bungie API key (not a client secret).
  final String apiKey;

  /// Platform base URL (e.g. `https://www.bungie.net/Platform`).
  final Uri baseUrl;

  final BungieHttpTransport transport;

  /// Optional observer for throttle / rate-limit signals.
  final RateLimitHook? onRateLimit;

  /// Optional default Bearer token applied when a call omits [accessToken].
  final String? defaultAccessToken;

  /// GET path under Platform base (or absolute URL); unwraps `Response`.
  Future<Object?> getJson(
    String path, {
    String? accessToken,
    Map<String, String>? queryParameters,
  }) {
    return _send(
      method: 'GET',
      path: path,
      accessToken: accessToken,
      queryParameters: queryParameters,
    );
  }

  /// POST JSON body; unwraps `Response`.
  Future<Object?> postJson(
    String path, {
    Object? body,
    String? accessToken,
  }) {
    return _send(
      method: 'POST',
      path: path,
      accessToken: accessToken,
      body: body,
    );
  }

  Future<Object?> _send({
    required String method,
    required String path,
    String? accessToken,
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _resolveUri(path, queryParameters);
    final token = accessToken ?? defaultAccessToken;
    final headers = <String, String>{
      'X-API-Key': apiKey,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    String? encodedBody;
    if (body != null) {
      headers['Content-Type'] = 'application/json';
      encodedBody = jsonEncode(body);
    } else if (method == 'POST') {
      headers['Content-Type'] = 'application/json';
      encodedBody = '{}';
    }

    final request = BungieHttpRequest(
      method: method,
      uri: uri,
      headers: headers,
      body: encodedBody,
    );

    final raw = await transport(request);
    return _handleResponse(path: path, uri: uri, raw: raw);
  }

  Object? _handleResponse({
    required String path,
    required Uri uri,
    required BungieHttpResponse raw,
  }) {
    final pathLabel = path.isEmpty ? uri.toString() : path;

    if (raw.statusCode == 429) {
      final retryAfter = _parseRetryAfterSeconds(raw.headers);
      final signal = RateLimitSignal(
        path: pathLabel,
        source: RateLimitSource.http,
        throttleSeconds: retryAfter,
        httpStatus: 429,
      );
      _emitRateLimit(signal);
      throw BungieHttpException(
        'Bungie Platform returned 429: Too Many Requests',
        statusCode: 429,
        bodySnippet: _snippet(raw.body),
        throttleSeconds: retryAfter,
        rateLimitSignal: signal,
      );
    }

    if (raw.statusCode < 200 || raw.statusCode >= 300) {
      throw BungieHttpException(
        'Bungie Platform returned ${raw.statusCode}',
        statusCode: raw.statusCode,
        bodySnippet: _snippet(raw.body),
      );
    }

    final envelope = parseBungieEnvelope(raw.body);

    if (!envelope.isSuccess) {
      final isThrottle = envelope.throttleSeconds > 0 ||
          envelope.errorCode == kBungieThrottleErrorCode;
      RateLimitSignal? signal;
      if (isThrottle) {
        signal = RateLimitSignal(
          path: pathLabel,
          source: RateLimitSource.envelope,
          throttleSeconds:
              envelope.throttleSeconds > 0 ? envelope.throttleSeconds : null,
          errorCode: envelope.errorCode,
          httpStatus: raw.statusCode,
        );
        _emitRateLimit(signal);
      }

      final msg = envelope.message ?? 'Bungie API error';
      throw BungiePlatformException(
        'Bungie API error: $msg',
        errorCode: envelope.errorCode,
        throttleSeconds: envelope.throttleSeconds,
        errorStatus: envelope.errorStatus,
        rateLimitSignal: signal,
      );
    }

    // Success with positive ThrottleSeconds is unusual; surface via hook only
    // when > 0 so callers can slow down without failing the request.
    if (envelope.throttleSeconds > 0) {
      _emitRateLimit(
        RateLimitSignal(
          path: pathLabel,
          source: RateLimitSource.envelope,
          throttleSeconds: envelope.throttleSeconds,
          errorCode: envelope.errorCode,
          httpStatus: raw.statusCode,
        ),
      );
    }

    return envelope.response;
  }

  void _emitRateLimit(RateLimitSignal signal) {
    onRateLimit?.call(signal);
  }

  Uri _resolveUri(String path, Map<String, String>? queryParameters) {
    final Uri resolved;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      resolved = Uri.parse(path);
    } else {
      final normalized = path.startsWith('/') ? path.substring(1) : path;
      resolved = baseUrl.replace(
        path: _joinPaths(baseUrl.path, normalized),
      );
    }
    if (queryParameters == null || queryParameters.isEmpty) {
      return resolved;
    }
    return resolved.replace(
      queryParameters: {
        ...resolved.queryParameters,
        ...queryParameters,
      },
    );
  }

  static String _joinPaths(String basePath, String relative) {
    final a = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    if (a.isEmpty) return '/$relative';
    return '$a/$relative';
  }

  static Uri _normalizeBase(Uri base) {
    final path = base.path.endsWith('/') && base.path.length > 1
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(path: path.isEmpty ? '' : path);
  }

  static String _requireApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      throw const BungieConfigException(
        'Bungie API key is required (public X-API-Key; never CLIENT_SECRET)',
      );
    }
    return apiKey;
  }

  static int? _parseRetryAfterSeconds(Map<String, String> headers) {
    final raw = headers['retry-after'] ?? headers['Retry-After'];
    if (raw == null || raw.isEmpty) return null;
    final asInt = int.tryParse(raw.trim());
    if (asInt != null) return asInt;
    return null;
  }

  static String _snippet(String body, [int max = 200]) {
    if (body.length <= max) return body;
    return '${body.substring(0, max)}…';
  }
}
