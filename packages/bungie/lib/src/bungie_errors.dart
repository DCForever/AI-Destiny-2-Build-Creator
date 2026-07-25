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
class BungiePlatformException extends BungieClientException {
  const BungiePlatformException(
    super.message, {
    required this.errorCode,
    this.throttleSeconds = 0,
    this.errorStatus,
    this.rateLimitSignal,
  });

  final int errorCode;
  final int throttleSeconds;
  final String? errorStatus;
  final RateLimitSignal? rateLimitSignal;
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
