import 'rate_limit.dart';

/// Base class for Bungie client failures.
sealed class BungieClientException implements Exception {
  const BungieClientException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// HTTP / transport layer failure (non-2xx or transport issues surfaced as status).
class BungieHttpException extends BungieClientException {
  const BungieHttpException(
    super.message, {
    required this.statusCode,
    this.bodySnippet,
    this.throttleSeconds,
    this.rateLimitSignal,
  });

  final int statusCode;
  final String? bodySnippet;
  final int? throttleSeconds;
  final RateLimitSignal? rateLimitSignal;
}

/// Bungie Platform envelope reported non-success (`ErrorCode != 1`).
///
/// Also thrown when HTTP is non-2xx but the body is a normal Bungie envelope
/// (Bungie often returns HTTP 500 with ErrorCode/ErrorStatus/Message).
class BungiePlatformException extends BungieClientException {
  const BungiePlatformException(
    super.message, {
    required this.errorCode,
    this.throttleSeconds = 0,
    this.errorStatus,
    this.rateLimitSignal,
    this.statusCode,
  });

  final int errorCode;
  final int throttleSeconds;
  final String? errorStatus;
  final RateLimitSignal? rateLimitSignal;

  /// HTTP status when this exception came from a non-2xx response body.
  final int? statusCode;
}

/// Response body could not be parsed as a Bungie envelope.
class BungieParseException extends BungieClientException {
  const BungieParseException(
    super.message, {
    this.bodySnippet,
  });

  final String? bodySnippet;
}

/// Invalid client configuration (e.g. empty API key).
class BungieConfigException extends BungieClientException {
  const BungieConfigException(super.message);
}

/// OAuth token endpoint failure (HTTP non-success or unexpected body).
class BungieOAuthException extends BungieClientException {
  const BungieOAuthException(
    super.message, {
    this.statusCode,
    this.bodySnippet,
  });

  final int? statusCode;
  final String? bodySnippet;

  @override
  String toString() {
    final bits = <String>[message];
    if (statusCode != null) bits.add('HTTP $statusCode');
    final snippet = bodySnippet;
    if (snippet != null && snippet.isNotEmpty) bits.add(snippet);
    return bits.join(' — ');
  }
}
