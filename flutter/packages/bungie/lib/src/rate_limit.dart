/// How a rate-limit signal was detected.
enum RateLimitSource {
  /// HTTP status (typically 429) or Retry-After header.
  http,

  /// Platform envelope ThrottleSeconds / throttle ErrorCode.
  envelope,
}

/// Structured throttle observation for [RateLimitHook]s and exception metadata.
class RateLimitSignal {
  const RateLimitSignal({
    required this.path,
    required this.source,
    this.throttleSeconds,
    this.httpStatus,
    this.errorCode,
  });

  /// Request path or URL string.
  final String path;

  final RateLimitSource source;

  /// Seconds to wait when known (envelope or Retry-After).
  final int? throttleSeconds;

  final int? httpStatus;
  final int? errorCode;
}

/// Observer invoked when the client detects a rate-limit / throttle signal.
typedef RateLimitHook = void Function(RateLimitSignal signal);

/// Suggested cooperative delay from a [RateLimitSignal] (no auto-retry).
///
/// Returns null when no positive wait is indicated.
Duration? suggestedDelay(RateLimitSignal signal) {
  final seconds = signal.throttleSeconds;
  if (seconds == null || seconds <= 0) return null;
  return Duration(seconds: seconds);
}

/// Bungie platform codes commonly associated with throttling.
///
/// Callers should still prefer [BungieEnvelope.throttleSeconds] when present.
const int kBungieThrottleErrorCode = 1672;
